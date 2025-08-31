import XCTest
import FountainRuntime
import AuthGatewayPlugin
import Crypto

final class AuthGatewayPluginTests: XCTestCase {
    private func makeToken(secret: String, payload: [String: Any]) throws -> String {
        let headerData = try JSONSerialization.data(withJSONObject: ["alg": "HS256", "typ": "JWT"])
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        func b64(_ data: Data) -> String {
            data.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        }
        let header = b64(headerData)
        let payload = b64(payloadData)
        let signingInput = "\(header).\(payload)"
        let key = SymmetricKey(data: Data(secret.utf8))
        let sig = HMAC<SHA256>.authenticationCode(for: Data(signingInput.utf8), using: key)
        let signature = b64(Data(sig))
        return "\(signingInput).\(signature)"
    }

    func testBlocksUnauthorizedAccess() async throws {
        let plugin = AuthGatewayPlugin(secret: "secret")
        let body = try JSONEncoder().encode(ValidateRequest(token: "invalid"))
        let request = HTTPRequest(method: "POST", path: "/auth/validate", body: body)
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 401)
    }

    func testAllowsAuthorizedAccess() async throws {
        let plugin = AuthGatewayPlugin(secret: "secret")
        let payload: [String: Any] = ["exp": Int(Date().timeIntervalSince1970) + 60, "role": "user"]
        let token = try makeToken(secret: "secret", payload: payload)
        let body = try JSONEncoder().encode(ValidateRequest(token: token))
        let request = HTTPRequest(method: "POST", path: "/auth/validate", body: body)
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 200)
    }
}
