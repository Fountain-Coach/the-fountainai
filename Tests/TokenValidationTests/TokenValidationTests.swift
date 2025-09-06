import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@preconcurrency import Crypto
@testable import gateway_server

final class TokenValidationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = URLProtocol.registerClass(MockURLProtocol.self)
        MockURLProtocol.handlers = [:]
    }
    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.handlers = [:]
        super.tearDown()
    }

    func testEnvKeyProvider() {
        let defaultKey = EnvKeyProvider(environment: [:]).symmetricKey()
        XCTAssertEqual(Data(defaultKey.withUnsafeBytes { Data($0) }), Data("secret".utf8))
        let customKey = EnvKeyProvider(environment: ["GATEWAY_JWT_SECRET": "abc"]).symmetricKey()
        XCTAssertEqual(Data(customKey.withUnsafeBytes { Data($0) }), Data("abc".utf8))
    }

    func testCredentialStoreValidatorPaths() async throws {
        let secret = "s3cr3t"
        let now = Int(Date().timeIntervalSince1970)
        let fullPayload: [String: Any] = [
            "iss": "me",
            "aud": "you",
            "sub": "123",
            "exp": now + 60,
            "nbf": now - 60,
            "iat": now - 60,
            "jti": "id",
            "role": "admin"
        ]
        let token = try makeToken(payload: fullPayload, secret: secret)
        struct KP: KeyProvider, @unchecked Sendable { let k: SymmetricKey; func symmetricKey() -> SymmetricKey { k } }
        let key = KP(k: SymmetricKey(data: Data(secret.utf8)))
        let opts = JWTValidationOptions(issuer: "me", audience: "you", leewaySeconds: 0, requireJTI: true)
        let validator = CredentialStoreValidator(keyProvider: key, options: opts)
        let claims = await validator.validate(token: token)
        XCTAssertEqual(claims?.role, "admin")
        XCTAssertEqual(claims?.scopes, ["admin"])

        // expired
        let expired = try makeToken(payload: ["sub": "1", "exp": now - 10], secret: secret)
        XCTAssertNil(CredentialStoreValidator.verifyAndDecode(token: expired, key: key.k, options: JWTValidationOptions(leewaySeconds: 0)))
        // nbf in future
        let nbfFuture = try makeToken(payload: ["sub": "1", "exp": now + 60, "nbf": now + 120], secret: secret)
        XCTAssertNil(CredentialStoreValidator.verifyAndDecode(token: nbfFuture, key: key.k, options: JWTValidationOptions()))
        // issuer mismatch
        let issMismatch = try makeToken(payload: ["iss": "other", "sub": "1", "exp": now + 60], secret: secret)
        XCTAssertNil(CredentialStoreValidator.verifyAndDecode(token: issMismatch, key: key.k, options: JWTValidationOptions(issuer: "me")))
        // audience mismatch
        let audMismatch = try makeToken(payload: ["aud": "other", "sub": "1", "exp": now + 60], secret: secret)
        XCTAssertNil(CredentialStoreValidator.verifyAndDecode(token: audMismatch, key: key.k, options: JWTValidationOptions(audience: "you")))
        // require jti
        let missingJti = try makeToken(payload: ["sub": "1", "exp": now + 60], secret: secret)
        XCTAssertNil(CredentialStoreValidator.verifyAndDecode(token: missingJti, key: key.k, options: JWTValidationOptions(requireJTI: true)))
        // invalid base64 signature
        XCTAssertNil(CredentialStoreValidator.verifyAndDecode(token: "a.b.c?", key: key.k, options: JWTValidationOptions()))
        // signature with no padding needed (exercise padding branch)
        XCTAssertNil(CredentialStoreValidator.verifyAndDecode(token: "a.b.TWFu", key: key.k, options: JWTValidationOptions()))
    }

    func testHMACKeyValidator() async throws {
        let secret = "key"
        let payload: [String: Any] = ["sub": "1", "exp": Int(Date().timeIntervalSince1970) + 60, "role": "user"]
        let token = try makeToken(payload: payload, secret: secret)
        struct KP: KeyProvider, @unchecked Sendable { let key: SymmetricKey; func symmetricKey() -> SymmetricKey { key } }
        let validator = HMACKeyValidator(keyProvider: KP(key: SymmetricKey(data: Data(secret.utf8))))
        let claims = await validator.validate(token: token)
        XCTAssertEqual(claims?.scopes, ["user"])
    }

    func testJWKSKeyProvider() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let url = URL(string: "https://example.com/jwks")!
        let jwksJSON = "{\"keys\":[{\"kty\":\"oct\",\"k\":\"" + Data("jwksSecret".utf8).base64URLEncodedString() + "\"}]}"
        MockURLProtocol.handlers[url] = { _ in (200, Data(jwksJSON.utf8)) }
        guard let provider = JWKSKeyProvider(jwksURL: url.absoluteString, session: session) else { return XCTFail("provider") }
        await provider.refresh()
        let keyData = provider.symmetricKey().withUnsafeBytes { Data($0) }
        XCTAssertEqual(keyData, Data("jwksSecret".utf8))
        XCTAssertNil(JWKSKeyProvider(jwksURL: ""))
    }

    func testJWTValidationOptions() {
        setenv("GATEWAY_JWT_ISS", "envIss", 1)
        setenv("GATEWAY_JWT_AUD", "envAud", 1)
        setenv("GATEWAY_JWT_LEEWAY", "10", 1)
        setenv("GATEWAY_JWT_REQUIRE_JTI", "1", 1)
        let envOpts = JWTValidationOptions()
        XCTAssertEqual(envOpts.issuer, "envIss")
        XCTAssertEqual(envOpts.audience, "envAud")
        XCTAssertEqual(envOpts.leewaySeconds, 10)
        XCTAssertTrue(envOpts.requireJTI)
        let opts = JWTValidationOptions(issuer: "i", audience: "a", leewaySeconds: 5, requireJTI: true)
        XCTAssertEqual(opts.issuer, "i")
        XCTAssertEqual(opts.audience, "a")
        XCTAssertEqual(opts.leewaySeconds, 5)
        XCTAssertTrue(opts.requireJTI)
    }

    func testOAuth2Validator() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let url = URL(string: "https://example.com/introspect")!
        // success
        MockURLProtocol.handlers[url] = { req in
            let body = String(data: req.httpBody ?? Data(), encoding: .utf8)
            XCTAssertEqual(body, "token=good")
            XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
            XCTAssertNotNil(req.value(forHTTPHeaderField: "Authorization"))
            let json = "{\"active\":true,\"scope\":\"s1 s2\",\"role\":\"r1\"}"
            return (200, Data(json.utf8))
        }
        var validator = OAuth2Validator(introspectionURL: url, clientId: "id", clientSecret: "secret", session: session)
        var claims = await validator.validate(token: "good")
        XCTAssertEqual(claims?.role, "r1")
        XCTAssertEqual(claims?.scopes, ["s1", "s2"])
        // inactive
        MockURLProtocol.handlers[url] = { _ in (200, Data("{\"active\":false}".utf8)) }
        validator = OAuth2Validator(introspectionURL: url, session: session)
        claims = await validator.validate(token: "bad")
        XCTAssertNil(claims)
        // invalid JSON
        MockURLProtocol.handlers[url] = { _ in (200, Data("oops".utf8)) }
        claims = await validator.validate(token: "bad")
        XCTAssertNil(claims)
    }

    func testErrorTypes() {
        _ = UnauthorizedError()
        _ = ForbiddenError()
    }
}

private class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handlers: [URL: (URLRequest) -> (Int, Data)] = [:]
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return handlers[url] != nil
    }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let url = request.url, let handler = MockURLProtocol.handlers[url] else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        var req = request
        if req.httpBody == nil, let stream = req.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var data = Data()
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: bufferSize)
                if read <= 0 { break }
                data.append(buffer, count: read)
            }
            req.httpBody = data
        }
        let (status, data) = handler(req)
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

private func makeToken(payload: [String: Any], secret: String) throws -> String {
    let header: [String: Any] = ["alg": "HS256", "typ": "JWT"]
    let headerData = try JSONSerialization.data(withJSONObject: header)
    let payloadData = try JSONSerialization.data(withJSONObject: payload)
    let header64 = headerData.base64URLEncodedString()
    let payload64 = payloadData.base64URLEncodedString()
    let signingInput = "\(header64).\(payload64)"
    let key = SymmetricKey(data: Data(secret.utf8))
    let signature = HMAC<SHA256>.authenticationCode(for: Data(signingInput.utf8), using: key)
    let sig64 = Data(signature).base64URLEncodedString()
    return "\(signingInput).\(sig64)"
}

private extension Data {
    func base64URLEncodedString() -> String {
        self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
