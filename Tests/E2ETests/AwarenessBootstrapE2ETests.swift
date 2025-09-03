import XCTest
@testable import AwarenessService
@testable import BootstrapService
@testable import FountainStoreClient

final class AwarenessBootstrapE2ETests: XCTestCase {
    func testBootstrapThenAwarenessSummaryEndToEnd() async throws {
        let shared = FountainStoreClient(client: EmbeddedFountainStoreClient())
        let bootstrap = BootstrapRouter(persistence: shared)
        let awareness = AwarenessRouter(persistence: shared)

        // 1) bootstrap corpus init (creates corpus and seeds roles)
        let initResp = try await bootstrap.route(.init(method: "POST", path: "/bootstrap/corpus/init", body: try JSONEncoder().encode(BootstrapService.InitIn(corpusId: "e2e"))))
        XCTAssertEqual(initResp.status, 200)

        // 2) bootstrap baseline (also persists drift + patterns asynchronously)
        _ = try await bootstrap.route(.init(method: "POST", path: "/bootstrap/baseline", body: try JSONEncoder().encode(BootstrapService.BaselineIn(corpusId: "e2e", baselineId: "b1", content: "hello"))))

        // 3) awareness summary for the corpus
        let summaryResp = try await awareness.route(.init(method: "GET", path: "/corpus/summary/e2e"))
        XCTAssertEqual(summaryResp.status, 200)
        let sum = try JSONDecoder().decode(AwarenessService.HistorySummaryResponse.self, from: summaryResp.body)
        XCTAssertTrue(sum.summary.contains("baselines=1"))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
