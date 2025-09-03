import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import gateway_server
@testable import AwarenessService
@testable import FountainStoreClient

final class RoleGuardMethodProxyTests: XCTestCase {
    @MainActor
    func testMethodSpecificRules() async throws {
        // Upstream awareness
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        await svc.ensureCollections()
        let upstream = NIOHTTPServer(kernel: makeAwarenessKernel(service: svc))
        let upstreamPort = try await upstream.start(port: 0)

        // RoleGuard applies only to POST; GET should pass without token
        let guardPlugin = RoleGuardPlugin(rules: ["/awareness": RoleRequirement(roles: ["admin"], methods: ["POST"])])

        // Gateway route config
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("routes.json")
        struct Route: Codable { var id: String; var path: String; var target: String; var methods: [String]; var rateLimit: Int?; var proxyEnabled: Bool? }
        let routes = [Route(id: "awareness", path: "/awareness", target: "http://127.0.0.1:\(upstreamPort)", methods: ["GET","POST"], rateLimit: nil, proxyEnabled: true)]
        try JSONEncoder().encode(routes).write(to: file)

        let server = GatewayServer(plugins: [guardPlugin], zoneManager: nil, routeStoreURL: file)
        let port = 9137
        Task { try await server.start(port: port) }
        try await Task.sleep(nanoseconds: 100_000_000)

        // GET should pass without token
        let (gdata, gresp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/awareness/health")!)
        XCTAssertEqual((gresp as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertTrue((String(data: gdata, encoding: .utf8) ?? "").contains("ok"))

        // POST to /awareness/corpus/init should enforce admin role
        var req = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/awareness/corpus/init")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(InitIn(corpusId: "m1"))
        // No token -> 401
        let (_, r1) = try await URLSession.shared.data(for: req)
        XCTAssertEqual((r1 as? HTTPURLResponse)?.statusCode, 401)
        // Wrong role -> 403
        let store = CredentialStore()
        let bad = try store.signJWT(subject: "c", expiresAt: Date().addingTimeInterval(3600), role: "user")
        req.setValue("Bearer \(bad)", forHTTPHeaderField: "Authorization")
        let (_, r2) = try await URLSession.shared.data(for: req)
        XCTAssertEqual((r2 as? HTTPURLResponse)?.statusCode, 403)
        // Admin role -> 200
        let good = try store.signJWT(subject: "c", expiresAt: Date().addingTimeInterval(3600), role: "admin")
        req.setValue("Bearer \(good)", forHTTPHeaderField: "Authorization")
        let (_, r3) = try await URLSession.shared.data(for: req)
        XCTAssertEqual((r3 as? HTTPURLResponse)?.statusCode, 200)

        try await server.stop(); try await upstream.stop()
    }
}

