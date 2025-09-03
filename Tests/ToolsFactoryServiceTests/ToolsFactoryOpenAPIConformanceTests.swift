import XCTest
@testable import ToolsFactoryService
@testable import FountainStoreClient

final class ToolsFactoryOpenAPIConformanceTests: XCTestCase {
    func testListToolsResponseShapeMatchesOpenAPI() async throws {
        let manifest = ToolManifest(
            image: .init(name: "img", tarball: "t", sha256: "s", qcow2: "q", qcow2_sha256: "qs"),
            tools: [:],
            operations: []
        )
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        await svc.ensureCollections()
        let router = ToolsFactoryRouter(service: svc, adapters: [:], manifest: manifest, defaultCorpusId: "tf")
        // Seed a couple of functions
        _ = try await svc.addFunction(.init(corpusId: "tf", functionId: "op.a", name: "A", description: "da", httpMethod: "GET", httpPath: "/a"))
        _ = try await svc.addFunction(.init(corpusId: "tf", functionId: "op.b", name: "B", description: "db", httpMethod: "POST", httpPath: "/b"))

        let resp = try await router.route(.init(method: "GET", path: "/tools?page=1&page_size=2", body: Data()))
        XCTAssertEqual(resp.status, 200)
        let obj = try JSONSerialization.jsonObject(with: resp.body) as? [String: Any]
        // Required top-level properties
        XCTAssertNotNil(obj?["functions"]) ; XCTAssertNotNil(obj?["page"]) ; XCTAssertNotNil(obj?["page_size"]) ; XCTAssertNotNil(obj?["total"]) 
        XCTAssertTrue(obj?["page"] is Int)
        XCTAssertTrue(obj?["page_size"] is Int)
        XCTAssertTrue(obj?["total"] is Int)
        guard let arr = obj?["functions"] as? [[String: Any]], let first = arr.first else {
            return XCTFail("functions is not an array")
        }
        // Required function fields per OpenAPI
        XCTAssertNotNil(first["function_id"]) ; XCTAssertNotNil(first["name"]) ; XCTAssertNotNil(first["description"]) ; XCTAssertNotNil(first["http_method"]) ; XCTAssertNotNil(first["http_path"])
        XCTAssertTrue(first["function_id"] is String)
        XCTAssertTrue(first["name"] is String)
        XCTAssertTrue(first["description"] is String)
        XCTAssertTrue(first["http_method"] is String)
        XCTAssertTrue(first["http_path"] is String)
    }

    func testServesOpenAPISpec() async throws {
        let router = ToolsFactoryRouter(service: nil, adapters: [:], manifest: ToolManifest(image: .init(name: "", tarball: "", sha256: "", qcow2: "", qcow2_sha256: ""), tools: [:], operations: []))
        let resp = try await router.route(.init(method: "GET", path: "/openapi.yaml"))
        XCTAssertEqual(resp.status, 200)
        let text = String(data: resp.body, encoding: .utf8) ?? ""
        XCTAssertTrue(text.contains("FountainAI Tools Factory Service"))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

