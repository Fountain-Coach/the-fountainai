import XCTest
import FountainRuntime
import RateLimiterGatewayPlugin

final class RateLimiterGatewayPluginTests: XCTestCase {
    func testCheckUsesLLM() async throws {
        let plugin = RateLimiterGatewayPlugin()
        let body = try JSONEncoder().encode(RateLimitCheckRequest(routeId: "r", clientId: "c", limitPerMinute: nil))
        let request = HTTPRequest(method: "POST", path: "/rate-limit/check", body: body)
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 200)
    }
}
