import XCTest
@testable import AwarenessService
@testable import FountainStoreClient

final class AwarenessServiceTests: XCTestCase {
    func makeRouter() -> AwarenessRouter {
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        return AwarenessRouter(persistence: svc)
    }

    func testHealth() async throws {
        let router = makeRouter()
        let resp = try await router.route(.init(method: "GET", path: "/health"))
        XCTAssertEqual(resp.status, 200)
        let obj = try JSONSerialization.jsonObject(with: resp.body) as? [String: Any]
        XCTAssertEqual(obj?["status"] as? String, "ok")
    }

    func testInitAndBaselineAndSummaryFlow() async throws {
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        let router = AwarenessRouter(persistence: svc)
        // init corpus
        let initBody = try JSONEncoder().encode(InitIn(corpusId: "c1"))
        let initResp = try await router.route(.init(method: "POST", path: "/corpus/init", body: initBody))
        XCTAssertEqual(initResp.status, 200)
        // add baseline
        let baseBody = try JSONEncoder().encode(BaselineRequest(corpusId: "c1", baselineId: "b1", content: "hello"))
        let baseResp = try await router.route(.init(method: "POST", path: "/corpus/baseline", body: baseBody))
        XCTAssertEqual(baseResp.status, 200)
        // add reflection
        let reflBody = try JSONEncoder().encode(ReflectionRequest(corpusId: "c1", reflectionId: "r1", question: "q", content: "a"))
        let reflResp = try await router.route(.init(method: "POST", path: "/corpus/reflections", body: reflBody))
        XCTAssertEqual(reflResp.status, 200)
        // summary
        let sumResp = try await router.route(.init(method: "GET", path: "/corpus/summary/c1"))
        XCTAssertEqual(sumResp.status, 200)
        let sum = try JSONDecoder().decode(HistorySummaryResponse.self, from: sumResp.body)
        XCTAssertTrue(sum.summary.contains("baselines=1"))
    }

    func testAnalyticsHistoryAndSemanticArc() async throws {
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        let router = AwarenessRouter(persistence: svc)
        _ = try await router.route(.init(method: "POST", path: "/corpus/init", body: try JSONEncoder().encode(InitIn(corpusId: "c9"))))
        _ = try await router.route(.init(method: "POST", path: "/corpus/baseline", body: try JSONEncoder().encode(BaselineRequest(corpusId: "c9", baselineId: "b1", content: "hello"))))
        _ = try await router.route(.init(method: "POST", path: "/corpus/reflections", body: try JSONEncoder().encode(ReflectionRequest(corpusId: "c9", reflectionId: "r1", question: "q", content: "a"))))
        _ = try await router.route(.init(method: "POST", path: "/corpus/drift", body: try JSONEncoder().encode(DriftRequest(corpusId: "c9", driftId: "d1", content: "x"))))
        _ = try await router.route(.init(method: "POST", path: "/corpus/patterns", body: try JSONEncoder().encode(PatternsRequest(corpusId: "c9", patternsId: "p1", content: "y"))))
        let (hData, _) = (try await { () async throws -> (Data, Void) in
            let resp = try await router.route(.init(method: "GET", path: "/corpus/history?corpus_id=c9"))
            return (resp.body, ())
        }())
        let hObj = try JSONSerialization.jsonObject(with: hData) as? [String: Any]
        XCTAssertTrue((hObj?["total"] as? Int ?? 0) >= 4)
        let (aData, _) = (try await { () async throws -> (Data, Void) in
            let resp = try await router.route(.init(method: "GET", path: "/corpus/semantic-arc?corpus_id=c9"))
            return (resp.body, ())
        }())
        let aObj = try JSONSerialization.jsonObject(with: aData) as? [String: Any]
        XCTAssertNotNil(aObj?["arc"])
        XCTAssertTrue((aObj?["total"] as? Int ?? 0) >= 4)
        if let arc = aObj?["arc"] as? [[String: Any]], let first = arc.first {
            XCTAssertNotNil(first["phase"]) ; XCTAssertNotNil(first["weight"]) ; XCTAssertNotNil(first["pct"])
        }
    }

    func testStreamHistoryAnalyticsSSE() async throws {
        let router = makeRouter()
        let resp = try await router.route(.init(method: "GET", path: "/corpus/history/stream?sse=1"))
        XCTAssertEqual(resp.status, 200)
        XCTAssertEqual(resp.headers["Content-Type"], "text/event-stream")
    }

    func testMetricsUptime() async throws {
        let router = makeRouter()
        let resp = try await router.route(.init(method: "GET", path: "/metrics"))
        XCTAssertEqual(resp.status, 200)
        let text = String(decoding: resp.body, as: UTF8.self)
        XCTAssertTrue(text.starts(with: "awareness_uptime_seconds"))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
