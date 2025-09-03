import XCTest
@testable import ToolsFactoryService
@testable import FountainStoreClient

final class ToolsFactoryEndpointsTests: XCTestCase {
    func testRegisterAndListTools() async throws {
        let manifest = ToolManifest(
            image: .init(name: "img", tarball: "t", sha256: "s", qcow2: "q", qcow2_sha256: "qs"),
            tools: [:],
            operations: []
        )
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        await svc.ensureCollections()
        let router = ToolsFactoryRouter(service: svc, adapters: [:], manifest: manifest, defaultCorpusId: "tf")

        // Register from an OpenAPI doc
        let openapi: [String: Any] = [
            "openapi": "3.1.0",
            "paths": [
                "/alpha": [
                    "get": ["operationId": "alpha.get", "summary": "Alpha Get", "description": "desc A"],
                    "post": ["operationId": "alpha.create", "summary": "Alpha Create"]
                ],
                "/beta": [
                    "delete": ["operationId": "beta.delete"]
                ]
            ]
        ]
        let body = try JSONSerialization.data(withJSONObject: openapi)
        let req = HTTPRequest(method: "POST", path: "/tools/register?corpusId=tf", body: body)
        let reg = try await router.route(req)
        XCTAssertEqual(reg.status, 200)

        // List with pagination (page 1 size 2)
        let list1 = try await router.route(.init(method: "GET", path: "/tools?page=1&page_size=2", body: Data()))
        XCTAssertEqual(list1.status, 200)
        let obj1 = try JSONSerialization.jsonObject(with: list1.body) as? [String: Any]
        XCTAssertEqual(obj1?["page"] as? Int, 1)
        XCTAssertEqual(obj1?["page_size"] as? Int, 2)
        XCTAssertEqual(obj1?["total"] as? Int, 3)

        // Page 2 should have 1 item
        let list2 = try await router.route(.init(method: "GET", path: "/tools?page=2&page_size=2", body: Data()))
        let obj2 = try JSONSerialization.jsonObject(with: list2.body) as? [String: Any]
        XCTAssertEqual(obj2?["page"] as? Int, 2)
        XCTAssertEqual(obj2?["page_size"] as? Int, 2)
        XCTAssertEqual(obj2?["total"] as? Int, 3)
        let arr2 = obj2?["functions"] as? [Any]
        XCTAssertEqual(arr2?.count, 1)
    }

    func testMetricsEndpoint() async throws {
        let manifest = ToolManifest(
            image: .init(name: "img", tarball: "t", sha256: "s", qcow2: "q", qcow2_sha256: "qs"),
            tools: [:],
            operations: []
        )
        let router = ToolsFactoryRouter(service: nil, adapters: [:], manifest: manifest)
        let resp = try await router.route(.init(method: "GET", path: "/metrics", body: Data()))
        XCTAssertEqual(resp.status, 200)
        let text = String(data: resp.body, encoding: .utf8) ?? ""
        XCTAssertTrue(text.contains("tools_factory_uptime_seconds"))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

