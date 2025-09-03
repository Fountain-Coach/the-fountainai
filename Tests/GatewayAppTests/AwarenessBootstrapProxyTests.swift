import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import gateway_server
@testable import AwarenessService
@testable import BootstrapService
@testable import FountainStoreClient

final class AwarenessBootstrapProxyTests: XCTestCase {
    @MainActor
    func testGatewayProxiesAwarenessAndBootstrap() async throws {
        // Start upstream Awareness
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        await svc.ensureCollections()
        let awarenessKernel = makeAwarenessKernel(service: svc)
        let awareness = NIOHTTPServer(kernel: awarenessKernel)
        let awarenessPort = try await awareness.start(port: 0)

        // Start upstream Bootstrap (same svc so data flows)
        let bootstrapKernel = makeBootstrapKernel(service: svc)
        let bootstrap = NIOHTTPServer(kernel: bootstrapKernel)
        let bootstrapPort = try await bootstrap.start(port: 0)

        // Prepare gateway routes
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("routes.json")
        struct Route: Codable { var id: String; var path: String; var target: String; var methods: [String]; var rateLimit: Int?; var proxyEnabled: Bool? }
        let routes = [
            Route(id: "awareness", path: "/awareness", target: "http://127.0.0.1:\(awarenessPort)", methods: ["GET","POST"], rateLimit: 100, proxyEnabled: true),
            Route(id: "bootstrap", path: "/bootstrap", target: "http://127.0.0.1:\(bootstrapPort)", methods: ["GET","POST"], rateLimit: 100, proxyEnabled: true)
        ]
        try JSONEncoder().encode(routes).write(to: file)

        // Start gateway
        let server = GatewayServer(manager: CertificateManager(scriptPath: "/usr/bin/true", interval: 3600), plugins: [], zoneManager: nil, routeStoreURL: file)
        let gwPort: Int = 9131
        Task { try await server.start(port: gwPort) }
        try await Task.sleep(nanoseconds: 100_000_000)

        // 1) Bootstrap corpus
        var req = URLRequest(url: URL(string: "http://127.0.0.1:\(gwPort)/bootstrap/corpus/init")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(BootstrapService.InitIn(corpusId: "gw-e2e"))
        let (_, bResp) = try await URLSession.shared.data(for: req)
        XCTAssertEqual((bResp as? HTTPURLResponse)?.statusCode, 200)

        // 2) Bootstrap baseline
        var bReq = URLRequest(url: URL(string: "http://127.0.0.1:\(gwPort)/bootstrap/baseline")!)
        bReq.httpMethod = "POST"
        bReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        bReq.httpBody = try JSONEncoder().encode(BootstrapService.BaselineIn(corpusId: "gw-e2e", baselineId: "b1", content: "hello"))
        let (_, baseResp) = try await URLSession.shared.data(for: bReq)
        XCTAssertEqual((baseResp as? HTTPURLResponse)?.statusCode, 200)

        // 3) Awareness summary
        let (data, sResp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(gwPort)/awareness/corpus/summary/gw-e2e")!)
        XCTAssertEqual((sResp as? HTTPURLResponse)?.statusCode, 200)
        let sum = try JSONDecoder().decode(AwarenessService.HistorySummaryResponse.self, from: data)
        XCTAssertTrue(sum.summary.contains("baselines=1"))

        try await server.stop()
        try await awareness.stop()
        try await bootstrap.stop()
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

