import XCTest
@testable import AwarenessService
@testable import FountainStoreClient

final class AwarenessOpenAPIConformanceTests: XCTestCase {
    func testHealthMatchesSchema() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = AwarenessRouter(persistence: svc)
        let resp = try await router.route(.init(method: "GET", path: "/health"))
        XCTAssertEqual(resp.status, 200)
        let obj = try JSONSerialization.jsonObject(with: resp.body) as? [String: Any]
        XCTAssertNotNil(obj?["status"]) ; XCTAssertTrue(obj?["status"] is String)
    }

    func testInitializeCorpusMatchesSchema() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = AwarenessRouter(persistence: svc)
        let body = try JSONEncoder().encode(InitIn(corpusId: "ci1"))
        let resp = try await router.route(.init(method: "POST", path: "/corpus/init", body: body))
        XCTAssertEqual(resp.status, 200)
        let out = try JSONDecoder().decode(InitOut.self, from: resp.body)
        XCTAssertTrue(out.message.contains("ci1"))
    }
    func testReflectionSummaryMatchesSchema() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = AwarenessRouter(persistence: svc)
        _ = try await svc.addReflection(.init(corpusId: "c1", reflectionId: "r1", question: "q", content: "a"))
        let resp = try await router.route(.init(method: "GET", path: "/corpus/reflections/c1"))
        XCTAssertEqual(resp.status, 200)
        let obj = try JSONSerialization.jsonObject(with: resp.body) as? [String: Any]
        XCTAssertNotNil(obj?["message"]) ; XCTAssertTrue(obj?["message"] is String)
    }

    func testHistorySummaryMatchesSchema() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = AwarenessRouter(persistence: svc)
        _ = try await svc.addBaseline(.init(corpusId: "c2", baselineId: "b1", content: "x"))
        let resp = try await router.route(.init(method: "GET", path: "/corpus/history/c2"))
        XCTAssertEqual(resp.status, 200)
        let obj = try JSONSerialization.jsonObject(with: resp.body) as? [String: Any]
        XCTAssertNotNil(obj?["summary"]) ; XCTAssertTrue(obj?["summary"] is String)
    }

    func testSummarizeHistoryMatchesSchema() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = AwarenessRouter(persistence: svc)
        _ = try await svc.addBaseline(.init(corpusId: "cs1", baselineId: "b1", content: "x"))
        _ = try await svc.addReflection(.init(corpusId: "cs1", reflectionId: "r1", question: "q", content: "a"))
        let resp = try await router.route(.init(method: "GET", path: "/corpus/summary/cs1"))
        XCTAssertEqual(resp.status, 200)
        let obj = try JSONSerialization.jsonObject(with: resp.body) as? [String: Any]
        XCTAssertNotNil(obj?["summary"]) ; XCTAssertTrue(obj?["summary"] is String)
    }

    func testListHistoryAnalyticsMatchesSchema() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = AwarenessRouter(persistence: svc)
        _ = try await svc.addBaseline(.init(corpusId: "ca1", baselineId: "b1", content: "x"))
        _ = try await svc.addReflection(.init(corpusId: "ca1", reflectionId: "r1", question: "q", content: "a"))
        _ = try await svc.addDrift(.init(corpusId: "ca1", driftId: "d1", content: "y"))
        _ = try await svc.addPatterns(.init(corpusId: "ca1", patternsId: "p1", content: "z"))
        let resp = try await router.route(.init(method: "GET", path: "/corpus/history?corpus_id=ca1"))
        XCTAssertEqual(resp.status, 200)
        let obj = try JSONSerialization.jsonObject(with: resp.body) as? [String: Any]
        XCTAssertNotNil(obj?["total"]) ; XCTAssertTrue(obj?["events"] is [[String: Any]])
    }

    func testReadSemanticArcMatchesSchema() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = AwarenessRouter(persistence: svc)
        _ = try await svc.addBaseline(.init(corpusId: "sa1", baselineId: "b1", content: "x"))
        _ = try await svc.addReflection(.init(corpusId: "sa1", reflectionId: "r1", question: "q", content: "a"))
        _ = try await svc.addDrift(.init(corpusId: "sa1", driftId: "d1", content: "y"))
        _ = try await svc.addPatterns(.init(corpusId: "sa1", patternsId: "p1", content: "z"))
        let resp = try await router.route(.init(method: "GET", path: "/corpus/semantic-arc?corpus_id=sa1"))
        XCTAssertEqual(resp.status, 200)
        let obj = try JSONSerialization.jsonObject(with: resp.body) as? [String: Any]
        XCTAssertNotNil(obj?["arc"]) ; XCTAssertNotNil(obj?["total"])
    }

    func testStreamHistoryAnalyticsMatchesSchema() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = AwarenessRouter(persistence: svc)
        let resp = try await router.route(.init(method: "GET", path: "/corpus/history/stream"))
        XCTAssertEqual(resp.status, 200)
        let obj = try JSONSerialization.jsonObject(with: resp.body) as? [String: Any]
        XCTAssertNotNil(obj)
    }

    func testMetricsMatchesSchema() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = AwarenessRouter(persistence: svc)
        let resp = try await router.route(.init(method: "GET", path: "/metrics"))
        XCTAssertEqual(resp.status, 200)
        let text = String(decoding: resp.body, as: UTF8.self)
        XCTAssertTrue(text.contains("awareness_uptime_seconds"))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

