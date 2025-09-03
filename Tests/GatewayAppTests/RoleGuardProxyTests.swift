import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import gateway_server
@testable import AwarenessService
@testable import FountainStoreClient

final class RoleGuardProxyTests: XCTestCase {
    @MainActor
    func test401And403And200() async throws {
        // Upstream awareness
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        await svc.ensureCollections()
        let awarenessKernel = makeAwarenessKernel(service: svc)
        let upstream = NIOHTTPServer(kernel: awarenessKernel)
        let upstreamPort = try await upstream.start(port: 0)

        // Routes
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("routes.json")
        struct Route: Codable { var id: String; var path: String; var target: String; var methods: [String]; var rateLimit: Int?; var proxyEnabled: Bool? }
        let routes = [Route(id: "awareness", path: "/awareness", target: "http://127.0.0.1:\(upstreamPort)", methods: ["GET","POST"], rateLimit: nil, proxyEnabled: true)]
        try JSONEncoder().encode(routes).write(to: file)

        // Gateway with RoleGuard requiring admin on /awareness
        let guardPlugin = RoleGuardPlugin(rules: ["/awareness": RoleRequirement(roles: ["admin"])])
        let server = GatewayServer(plugins: [guardPlugin], zoneManager: nil, routeStoreURL: file)
        let port = 9133
        Task { try await server.start(port: port) }
        try await Task.sleep(nanoseconds: 100_000_000)

        let url = URL(string: "http://127.0.0.1:\(port)/awareness/health")!

        // 401 without token
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let (_, r1) = try await URLSession.shared.data(for: req)
        XCTAssertEqual((r1 as? HTTPURLResponse)?.statusCode, 401)

        // 403 with wrong role
        let store = CredentialStore()
        let bad = try store.signJWT(subject: "client", expiresAt: Date().addingTimeInterval(3600), role: "user")
        req.setValue("Bearer \(bad)", forHTTPHeaderField: "Authorization")
        let (_, r2) = try await URLSession.shared.data(for: req)
        XCTAssertEqual((r2 as? HTTPURLResponse)?.statusCode, 403)

        // 200 with admin role
        let good = try store.signJWT(subject: "client", expiresAt: Date().addingTimeInterval(3600), role: "admin")
        req.setValue("Bearer \(good)", forHTTPHeaderField: "Authorization")
        let (_, r3) = try await URLSession.shared.data(for: req)
        XCTAssertEqual((r3 as? HTTPURLResponse)?.statusCode, 200)

        try await server.stop(); try await upstream.stop()
    }
}

