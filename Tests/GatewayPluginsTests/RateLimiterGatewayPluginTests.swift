import XCTest
import FountainRuntime
import RateLimiterGatewayPlugin

final class RateLimiterGatewayPluginTests: XCTestCase {
    func testThrottlesRequests() async throws {
        let plugin = RateLimiterGatewayPlugin(defaultLimit: 1)
        let body = try JSONEncoder().encode(RateLimitCheckRequest(routeId: "r", clientId: "c", limitPerMinute: nil))
        let request = HTTPRequest(method: "POST", path: "/rate-limit/check", body: body)
        let first = try await plugin.router.route(request)
        let second = try await plugin.router.route(request)
        let decoder = JSONDecoder()
        let firstResp = try decoder.decode(RateLimitCheckResponse.self, from: first?.body ?? Data())
        let secondResp = try decoder.decode(RateLimitCheckResponse.self, from: second?.body ?? Data())
        XCTAssertTrue(firstResp.allowed)
        XCTAssertFalse(secondResp.allowed)
    }

    func testLegitimateRequestsUnderLimitPass() async throws {
        let plugin = RateLimiterGatewayPlugin(defaultLimit: 2)
        let body = try JSONEncoder().encode(RateLimitCheckRequest(routeId: "r", clientId: "c", limitPerMinute: nil))
        let request = HTTPRequest(method: "POST", path: "/rate-limit/check", body: body)
        let first = try await plugin.router.route(request)
        let second = try await plugin.router.route(request)
        let decoder = JSONDecoder()
        let firstResp = try decoder.decode(RateLimitCheckResponse.self, from: first?.body ?? Data())
        let secondResp = try decoder.decode(RateLimitCheckResponse.self, from: second?.body ?? Data())
        XCTAssertTrue(firstResp.allowed)
        XCTAssertTrue(secondResp.allowed)
    }
}
