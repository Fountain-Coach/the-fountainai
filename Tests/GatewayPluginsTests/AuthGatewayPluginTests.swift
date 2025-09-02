import XCTest
import FountainRuntime
import AuthGatewayPlugin
final class AuthGatewayPluginTests: XCTestCase {
    func testValidateUsesLLM() async throws {
        let plugin = AuthGatewayPlugin()
        let body = try JSONEncoder().encode(ValidateRequest(token: "anything"))
        let request = HTTPRequest(method: "POST", path: "/auth/validate", body: body)
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 200)
    }
}
