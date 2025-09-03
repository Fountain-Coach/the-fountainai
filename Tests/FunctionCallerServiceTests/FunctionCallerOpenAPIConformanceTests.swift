import XCTest
@testable import FunctionCallerService
@testable import FountainStoreClient

final class FunctionCallerOpenAPIConformanceTests: XCTestCase {
    func testListFunctionsResponseShapeMatchesOpenAPI() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        await svc.ensureCollections()
        // Seed a function
        _ = try await svc.addFunction(.init(corpusId: "c1", functionId: "f1", name: "F1", description: "d1", httpMethod: "GET", httpPath: "/f1"))
        let router = FunctionCallerRouter(persistence: svc)
        let resp = try await router.route(.init(method: "GET", path: "/functions?page=1&page_size=1"))
        XCTAssertEqual(resp.status, 200)
        let obj = try JSONSerialization.jsonObject(with: resp.body) as? [String: Any]
        XCTAssertNotNil(obj?["functions"]) ; XCTAssertNotNil(obj?["page"]) ; XCTAssertNotNil(obj?["page_size"]) ; XCTAssertNotNil(obj?["total"])
        XCTAssertTrue(obj?["page"] is Int)
        XCTAssertTrue(obj?["page_size"] is Int)
        XCTAssertTrue(obj?["total"] is Int)
        guard let arr = obj?["functions"] as? [[String: Any]], let first = arr.first else {
            return XCTFail("functions array missing")
        }
        XCTAssertTrue(first["function_id"] is String)
        XCTAssertTrue(first["name"] is String)
        XCTAssertTrue(first["description"] is String)
        XCTAssertTrue(first["http_method"] is String)
        XCTAssertTrue(first["http_path"] is String)
    }

    func testMetricsEndpointReturnsPlainText() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let router = FunctionCallerRouter(persistence: svc)
        let resp = try await router.route(.init(method: "GET", path: "/metrics"))
        XCTAssertEqual(resp.status, 200)
        let text = String(data: resp.body, encoding: .utf8) ?? ""
        XCTAssertTrue(text.contains("function_caller_requests_total"))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
