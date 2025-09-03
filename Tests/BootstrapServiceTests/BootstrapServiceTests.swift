import XCTest
@testable import BootstrapService
@testable import FountainStoreClient

final class BootstrapServiceTests: XCTestCase {
    func testCorpusInitSeedsRoles() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = BootstrapRouter(persistence: svc)
        let body = try JSONEncoder().encode(InitIn(corpusId: "c2"))
        let resp = try await router.route(.init(method: "POST", path: "/bootstrap/corpus/init", body: body))
        XCTAssertEqual(resp.status, 200)
    }

    func testSeedRolesEndpoint() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = BootstrapRouter(persistence: svc)
        let body = try JSONEncoder().encode(RoleInitRequest(corpusId: "c3"))
        let resp = try await router.route(.init(method: "POST", path: "/bootstrap/roles/seed", body: body))
        XCTAssertEqual(resp.status, 200)
        let roles = try JSONDecoder().decode(RoleDefaults.self, from: resp.body)
        XCTAssertFalse(roles.drift.isEmpty)
    }

    func testSeedRolesShortcutEndpoint() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = BootstrapRouter(persistence: svc)
        let body = try JSONEncoder().encode(RoleInitRequest(corpusId: "c8"))
        let resp = try await router.route(.init(method: "POST", path: "/bootstrap/roles", body: body))
        XCTAssertEqual(resp.status, 200)
        let roles = try JSONDecoder().decode(RoleDefaults.self, from: resp.body)
        XCTAssertFalse(roles.view_creator.isEmpty)
    }

    func testBootstrapBaselinePersistsSlices() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = BootstrapRouter(persistence: svc)
        _ = try await router.route(.init(method: "POST", path: "/bootstrap/roles", body: try JSONEncoder().encode(RoleInitRequest(corpusId: "c4"))))
        let body = try JSONEncoder().encode(BaselineIn(corpusId: "c4", baselineId: "b42", content: "x"))
        let resp = try await router.route(.init(method: "POST", path: "/bootstrap/baseline", body: body))
        XCTAssertEqual(resp.status, 200)
    }

    func testSSEBaselineResponseShape() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let kernel = makeBootstrapKernel(service: svc)
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)
        var req = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/bootstrap/baseline?sse=1")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(BaselineIn(corpusId: "c5", baselineId: "b9", content: "x"))
        let (data, resp) = try await URLSession.shared.data(for: req)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        let ctype = (resp as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Type") ?? ""
        XCTAssertTrue(ctype.contains("text/event-stream"))
        let text = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(text.contains("event: drift"))
        XCTAssertTrue(text.contains("event: patterns"))
        XCTAssertTrue(text.contains("event: complete"))
        try await server.stop()
    }

    func testMetricsEndpoint() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = BootstrapRouter(persistence: svc)
        let resp = try await router.route(.init(method: "GET", path: "/metrics"))
        XCTAssertEqual(resp.status, 200)
        let text = String(data: resp.body, encoding: .utf8) ?? ""
        XCTAssertTrue(text.contains("bootstrap_uptime_seconds"))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
