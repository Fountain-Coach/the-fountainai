import XCTest
@testable import FountainRuntime

final class DNSMetricsTests: XCTestCase {
    func testWaitResolvesAfterTargetQueries() async throws {
        await DNSMetrics.shared.reset()
        let producer = Task {
            for _ in 0..<3 {
                await DNSMetrics.shared.record(query: "example.com", type: "A", hit: true)
                try? await Task.sleep(nanoseconds: 10_000_000)
            }
        }
        let reached = await DNSMetrics.shared.wait(forQueries: 3, timeout: 1.0)
        XCTAssertTrue(reached)
        _ = await producer.value
    }

    func testWaitTimesOutWhenNotReached() async throws {
        await DNSMetrics.shared.reset()
        let timedOut = await DNSMetrics.shared.wait(forQueries: 1, timeout: 0.05)
        XCTAssertFalse(timedOut)
    }

    func testExpositionIncludesTypeCounts() async {
        await DNSMetrics.shared.reset()
        await DNSMetrics.shared.record(query: "example.com", type: "A", hit: true)
        let text = await DNSMetrics.shared.exposition()
        XCTAssertTrue(text.contains("dns_queries_type_A_total 1"))
        XCTAssertTrue(text.contains("dns_hits_type_A_total 1"))
    }
}
