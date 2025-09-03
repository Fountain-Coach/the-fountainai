import XCTest
@testable import PlannerService
@testable import FountainStoreClient

final class PlannerServiceTests: XCTestCase {
    func testReasonEndpoint() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = PlannerRouter(persistence: svc)
        let reqObj = UserObjectiveRequest(objective: "test goal")
        let data = try JSONEncoder().encode(reqObj)
        let req = HTTPRequest(method: "POST", path: "/planner/reason", body: data)
        let resp = try await router.route(req)
        XCTAssertEqual(resp.status, 200)
        let plan = try JSONDecoder().decode(PlanResponse.self, from: resp.body)
        XCTAssertEqual(plan.objective, "test goal")
    }

    func testExecuteEndpoint() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = PlannerRouter(persistence: svc)
        let step = FunctionCall(name: "step1", arguments: ["a": "1"])
        let execReq = PlanExecutionRequest(objective: "obj", steps: [step])
        let data = try JSONEncoder().encode(execReq)
        let req = HTTPRequest(method: "POST", path: "/planner/execute", body: data)
        let resp = try await router.route(req)
        XCTAssertEqual(resp.status, 200)
        let result = try JSONDecoder().decode(ExecutionResult.self, from: resp.body)
        XCTAssertEqual(result.results.count, 1)
        XCTAssertEqual(result.results.first?.step, "step1")
    }

    func testListCorpora() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        _ = try await svc.createCorpus(.init(corpusId: "c1"))
        let router = PlannerRouter(persistence: svc)
        let resp = try await router.route(.init(method: "GET", path: "/planner/corpora"))
        XCTAssertEqual(resp.status, 200)
        let corpora = try JSONDecoder().decode([String].self, from: resp.body)
        XCTAssertEqual(corpora, ["c1"])
    }

    func testPostReflection() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = PlannerRouter(persistence: svc)
        let reqObj = ChatReflectionRequest(corpusId: "c1", message: "hello")
        let data = try JSONEncoder().encode(reqObj)
        let resp = try await router.route(.init(method: "POST", path: "/planner/reflections", body: data))
        XCTAssertEqual(resp.status, 200)
        let item = try JSONDecoder().decode(ReflectionItem.self, from: resp.body)
        XCTAssertEqual(item.content, "hello")
    }

    func testGetReflections() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        _ = try await svc.addReflection(.init(corpusId: "c1", reflectionId: "r1", question: "q", content: "a"))
        let router = PlannerRouter(persistence: svc)
        let resp = try await router.route(.init(method: "GET", path: "/planner/reflections/c1"))
        XCTAssertEqual(resp.status, 200)
        let history = try JSONDecoder().decode(HistoryListResponse.self, from: resp.body)
        XCTAssertEqual(history.reflections.count, 1)
    }

    func testGetSemanticArc() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        _ = try await svc.addReflection(.init(corpusId: "c1", reflectionId: "r1", question: "q", content: "a"))
        let router = PlannerRouter(persistence: svc)
        let resp = try await router.route(.init(method: "GET", path: "/planner/reflections/c1/semantic-arc"))
        XCTAssertEqual(resp.status, 200)
        let obj = try JSONSerialization.jsonObject(with: resp.body) as? [String: Any]
        XCTAssertEqual(obj?["total"] as? Int, 1)
    }

    func testMetricsEndpoint() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = PlannerRouter(persistence: svc)
        let resp = try await router.route(.init(method: "GET", path: "/metrics"))
        XCTAssertEqual(resp.status, 200)
        let text = String(data: resp.body, encoding: .utf8) ?? ""
        XCTAssertTrue(text.contains("planner_requests_total"))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
