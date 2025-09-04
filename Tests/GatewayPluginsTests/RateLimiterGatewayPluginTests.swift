import XCTest
import FountainRuntime
@testable import RateLimiterGatewayPlugin

final class RateLimiterGatewayPluginTests: XCTestCase {
    struct ThrowingClient: LLMClient {
        func call(prompt: String) async throws -> String { throw URLError(.badServerResponse) }
    }

    final class MutableDate: @unchecked Sendable {
        var value: Date
        init(_ value: Date) { self.value = value }
    }

    func testAllowThrottleResetAndStats() async throws {
        let dateBox = MutableDate(Date())
        let plugin = RateLimiterGatewayPlugin(defaultLimit: 2, client: ThrowingClient(), date: { dateBox.value })

        let first = await plugin.allow(routeId: "r", clientId: "c", limitPerMinute: nil)
        XCTAssertTrue(first)
        let second = await plugin.allow(routeId: "r", clientId: "c", limitPerMinute: nil)
        XCTAssertTrue(second)
        let third = await plugin.allow(routeId: "r", clientId: "c", limitPerMinute: nil)
        XCTAssertFalse(third)

        let firstStats = await plugin.stats()
        XCTAssertEqual(firstStats.allowed, 2)
        XCTAssertEqual(firstStats.throttled, 1)

        dateBox.value = dateBox.value.addingTimeInterval(60)
        let fourth = await plugin.allow(routeId: "r", clientId: "c", limitPerMinute: nil)
        XCTAssertTrue(fourth)

        let secondStats = await plugin.stats()
        XCTAssertEqual(secondStats.allowed, 3)
        XCTAssertEqual(secondStats.throttled, 1)

        let request = HTTPRequest(method: "GET", path: "/rate-limit/stats")
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 200)
        let statsResp = try JSONDecoder().decode(RateLimitStatsResponse.self, from: response?.body ?? Data())
        XCTAssertEqual(statsResp.allowed, 3)
        XCTAssertEqual(statsResp.throttled, 1)
    }
}
