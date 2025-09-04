import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import FountainRuntime
import AuthGatewayPlugin

private class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responseData: Data = Data()
    nonisolated(unsafe) static var error: Error?
    nonisolated(unsafe) static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        var req = request
        if req.httpBody == nil, let stream = req.httpBodyStream {
            stream.open()
            var data = Data()
            let bufferSize = 1024
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: bufferSize)
                if read > 0 { data.append(buffer, count: read) } else { break }
            }
            stream.close()
            req.httpBody = data
        }
        Self.lastRequest = req
        if let error = Self.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let response = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

final class AuthGatewayPluginTests: XCTestCase {
    func testValidateUsesLLM() async throws {
        let plugin = AuthGatewayPlugin()
        let body = try JSONEncoder().encode(ValidateRequest(token: "anything"))
        let request = HTTPRequest(method: "POST", path: "/auth/validate", body: body)
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 200)
    }

    func testClaimsUsesLLM() async throws {
        _ = URLProtocol.registerClass(MockURLProtocol.self)
        defer { URLProtocol.unregisterClass(MockURLProtocol.self); MockURLProtocol.lastRequest = nil }
        let token = "Bearer stub-token"
        MockURLProtocol.error = nil
        MockURLProtocol.responseData = Data("{\"ok\":true}".utf8)

        let plugin = AuthGatewayPlugin()
        let request = HTTPRequest(method: "POST", path: "/auth/claims", headers: ["Authorization": token])
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 200)

        let last = try XCTUnwrap(MockURLProtocol.lastRequest)
        let body = try XCTUnwrap(last.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
        XCTAssertEqual(json?["prompt"], token)
    }

    func testLLMErrorFallsBack() async throws {
        _ = URLProtocol.registerClass(MockURLProtocol.self)
        defer { URLProtocol.unregisterClass(MockURLProtocol.self) }
        MockURLProtocol.error = URLError(.badServerResponse)

        let plugin = AuthGatewayPlugin()
        let request = HTTPRequest(method: "POST", path: "/auth/claims", headers: ["Authorization": "Bearer token"])
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 200)
        let body = String(data: response?.body ?? Data(), encoding: .utf8)
        XCTAssertEqual(body, "{}")
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

