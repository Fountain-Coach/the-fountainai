import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import FountainRuntime
@testable import persist_server
@testable import FountainStoreClient

final class PersistServerTests: XCTestCase {
    func testCorporaCRUDAndPagination() async throws {
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        await svc.ensureCollections()
        let kernel = makePersistKernel(service: svc)
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)

        // Create corpora
        for id in ["alpha","beta"] {
            var req = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/corpora")!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(["corpusId": id])
            let (_, resp) = try await URLSession.shared.data(for: req)
            XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 201)
        }

        // List corpora
        var (data, resp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/corpora")!)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        var obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(obj?["total"] as? Int, 2)

        // Pagination
        (data, resp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/corpora?limit=1&offset=1")!)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let list = obj?["corpora"] as? [String]
        XCTAssertEqual(list?.count, 1)

        try await server.stop()
    }

    func testBaselinesAndReflections() async throws {
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        await svc.ensureCollections()
        let kernel = makePersistKernel(service: svc)
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)

        // Create corpus
        var req = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/corpora")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["corpusId": "c1"]) 
        _ = try await URLSession.shared.data(for: req)

        // Add baseline
        var bReq = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/corpora/c1/baselines")!)
        bReq.httpMethod = "POST"
        bReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        bReq.httpBody = try JSONEncoder().encode(["corpusId": "c1", "baselineId": "b1", "content": "hello"]) 
        let (_, bResp) = try await URLSession.shared.data(for: bReq)
        XCTAssertEqual((bResp as? HTTPURLResponse)?.statusCode, 200)

        // List baselines
        var (data, resp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/corpora/c1/baselines")!)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        var obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(obj?["total"] as? Int, 1)

        // Add reflection
        var rReq = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/corpora/c1/reflections")!)
        rReq.httpMethod = "POST"
        rReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        rReq.httpBody = try JSONEncoder().encode(["corpusId": "c1", "reflectionId": "r1", "question": "q1", "content": "a1"]) 
        let (_, rResp) = try await URLSession.shared.data(for: rReq)
        XCTAssertEqual((rResp as? HTTPURLResponse)?.statusCode, 200)

        // List reflections
        (data, resp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/corpora/c1/reflections")!)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(obj?["total"] as? Int, 1)

        try await server.stop()
    }

    func testFunctionsRegistry() async throws {
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        await svc.ensureCollections()
        let kernel = makePersistKernel(service: svc)
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)

        // Add functions to two corpora
        for (id, name, corpus) in [("f1","F1","cx"),("f2","F2","cx"),("g1","G1","cy")] {
            var req = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/corpora/\(corpus)/functions")!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            // corpusId in body is optional; server will enforce path-level corpusId if omitted or mismatched
            let body: [String: Any] = ["functionId": id, "name": name, "description": "d", "httpMethod": "GET", "httpPath": "/p"]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, resp) = try await URLSession.shared.data(for: req)
            XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        }

        // List functions
        var (data, resp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/functions")!)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        var obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(obj?["total"] as? Int, 3)

        // Get single function
        (data, resp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/functions/f2")!)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        let f = try JSONDecoder().decode(FunctionModel.self, from: data)
        XCTAssertEqual(f.functionId, "f2")
        XCTAssertEqual(f.corpusId, "cx")

        // List functions by corpus
        (data, resp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/corpora/cx/functions")!)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(obj?["total"] as? Int, 2)

        // Filtered search q=F1 global
        (data, resp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/functions?q=F1")!)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(obj?["total"] as? Int, 1)

        // Filtered search within corpus
        (data, resp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/corpora/cx/functions?q=F2")!)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(obj?["total"] as? Int, 1)

        try await server.stop()
    }

    func testMetricsEndpoint() async throws {
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        await svc.ensureCollections()
        let kernel = makePersistKernel(service: svc)
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)

        let (data, resp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/metrics")!)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        let body = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(body.contains("persist_uptime_seconds"))

        try await server.stop()
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
