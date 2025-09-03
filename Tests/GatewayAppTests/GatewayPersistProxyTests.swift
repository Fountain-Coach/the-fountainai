import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import gateway_server
@testable import FountainRuntime
@testable import persist_server
@testable import FountainStoreClient

final class GatewayPersistProxyTests: XCTestCase {
    @MainActor
    func testGatewayProxiesPersistRoutes() async throws {
        // Start a persist upstream on a random port
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        await svc.ensureCollections()
        let persistKernel = makePersistKernel(service: svc)
        let upstream = NIOHTTPServer(kernel: persistKernel)
        let persistPort = try await upstream.start(port: 0)

        // Prepare route persistence file
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("routes.json")
        struct Route: Codable { var id: String; var path: String; var target: String; var methods: [String]; var rateLimit: Int?; var proxyEnabled: Bool? }
        let route = [Route(id: "persist", path: "/persist", target: "http://127.0.0.1:\(persistPort)", methods: ["GET","POST"], rateLimit: nil, proxyEnabled: true)]
        try JSONEncoder().encode(route).write(to: file)

        // Start the gateway with routeStoreURL pointing to our file
        let manager = CertificateManager(scriptPath: "/usr/bin/true", interval: 3600)
        let server = GatewayServer(manager: manager, plugins: [], zoneManager: nil, routeStoreURL: file)
        Task { try await server.start(port: 9130) }
        try await Task.sleep(nanoseconds: 100_000_000)
        // Make a POST via the gateway to upstream Persist: create corpora
        var req = URLRequest(url: URL(string: "http://127.0.0.1:9130/persist/corpora")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["corpusId": "g1"]) 
        let (_, resp) = try await URLSession.shared.data(for: req)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 201)
        // second corpus
        req.httpBody = try JSONEncoder().encode(["corpusId": "g2"]) 
        let (_, resp2) = try await URLSession.shared.data(for: req)
        XCTAssertEqual((resp2 as? HTTPURLResponse)?.statusCode, 201)

        // Publish two functions in g1 via gateway proxy
        var fReq = URLRequest(url: URL(string: "http://127.0.0.1:9130/persist/corpora/g1/functions")!)
        fReq.httpMethod = "POST"
        fReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        fReq.httpBody = try JSONEncoder().encode(["functionId": "f1", "name": "F1", "description": "d", "httpMethod": "GET", "httpPath": "/f1"]) 
        let (_, fResp) = try await URLSession.shared.data(for: fReq)
        XCTAssertEqual((fResp as? HTTPURLResponse)?.statusCode, 200)
        fReq.httpBody = try JSONEncoder().encode(["functionId": "f2", "name": "F2", "description": "d2", "httpMethod": "POST", "httpPath": "/f2"]) 
        let (_, fResp2) = try await URLSession.shared.data(for: fReq)
        XCTAssertEqual((fResp2 as? HTTPURLResponse)?.statusCode, 200)

        // Publish a function in g2
        var gReq = URLRequest(url: URL(string: "http://127.0.0.1:9130/persist/corpora/g2/functions")!)
        gReq.httpMethod = "POST"
        gReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        gReq.httpBody = try JSONEncoder().encode(["functionId": "gx1", "name": "GX", "description": "gx", "httpMethod": "GET", "httpPath": "/gx"]) 
        let (_, gResp) = try await URLSession.shared.data(for: gReq)
        XCTAssertEqual((gResp as? HTTPURLResponse)?.statusCode, 200)

        // List functions via gateway proxy (global)
        let (data, lResp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:9130/persist/functions")!)
        XCTAssertEqual((lResp as? HTTPURLResponse)?.statusCode, 200)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(obj?["total"] as? Int, 3)

        // List functions via gateway proxy (by corpus)
        let (cxData, cxResp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:9130/persist/corpora/g1/functions")!)
        XCTAssertEqual((cxResp as? HTTPURLResponse)?.statusCode, 200)
        let cxObj = try JSONSerialization.jsonObject(with: cxData) as? [String: Any]
        XCTAssertEqual(cxObj?["total"] as? Int, 2)

        // Filter via q=F1
        let (qData, qResp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:9130/persist/functions?q=F1")!)
        XCTAssertEqual((qResp as? HTTPURLResponse)?.statusCode, 200)
        let qObj = try JSONSerialization.jsonObject(with: qData) as? [String: Any]
        XCTAssertEqual(qObj?["total"] as? Int, 1)

        // Corpus-scoped filter: q=F2 in g1 → 1
        let (qcxData, qcxResp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:9130/persist/corpora/g1/functions?q=F2")!)
        XCTAssertEqual((qcxResp as? HTTPURLResponse)?.statusCode, 200)
        let qcxObj = try JSONSerialization.jsonObject(with: qcxData) as? [String: Any]
        XCTAssertEqual(qcxObj?["total"] as? Int, 1)
        // In g2, q=F2 → 0
        let (qcyData, qcyResp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:9130/persist/corpora/g2/functions?q=F2")!)
        XCTAssertEqual((qcyResp as? HTTPURLResponse)?.statusCode, 200)
        let qcyObj = try JSONSerialization.jsonObject(with: qcyData) as? [String: Any]
        XCTAssertEqual(qcyObj?["total"] as? Int, 0)

        try await server.stop()
        try await upstream.stop()
    }
}

extension GatewayServer {
    var boundPort: Int? {
        // Reflection-free trick: hit /routes and read the port from URL is non-trivial; we add a helper if needed.
        // For tests we can assume default of 0 allocated, but we can simulate by trying a series of ports; keeping simple here.
        return nil
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
