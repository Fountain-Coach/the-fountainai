import XCTest
import FountainRuntime
import RateLimiterGatewayPlugin

final class GatewayPluginsTests: XCTestCase {
    func testInitialization() {
        let plugin = RateLimiterGatewayPlugin(defaultLimit: 1)
        XCTAssertNotNil(plugin.router)
    }

    func testAllowRespectsLimit() async {
        let plugin = RateLimiterGatewayPlugin(defaultLimit: 1)
        let first = await plugin.allow(routeId: "route", clientId: "client", limitPerMinute: nil)
        let second = await plugin.allow(routeId: "route", clientId: "client", limitPerMinute: nil)
        XCTAssertTrue(first)
        XCTAssertFalse(second)
    }

    func testRateLimitCheckRequiresBody() async throws {
        let handlers = Handlers()
        let request = HTTPRequest(method: "POST", path: "/rate-limit/check")
        let response = try await handlers.rateLimitCheck(request, body: nil)
        XCTAssertEqual(response.status, 400)
    }
}
