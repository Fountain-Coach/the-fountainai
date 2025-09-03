import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import gateway_server
@testable import AwarenessService
@testable import FountainStoreClient

final class RoleGuardDenyMethodProxyTests: XCTestCase {
    @MainActor
    func testDenySpecificMethod() async throws {
        // Upstream awareness
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        await svc.ensureCollections()
        let upstream = NIOHTTPServer(kernel: makeAwarenessKernel(service: svc))
        let upstreamPort = try await upstream.start(port: 0)

        // Deny POST on /awareness; GET should still pass
        let guardPlugin = RoleGuardPlugin(rules: ["/awareness": RoleRequirement(deny: true, methods: ["POST"])])

        // Gateway route config
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("routes.json")
        struct Route: Codable { var id: String; var path: String; var target: String; var methods: [String]; var rateLimit: Int?; var proxyEnabled: Bool? }
        let routes = [Route(id: "awareness", path: "/awareness", target: "http://127.0.0.1:\(upstreamPort)", methods: ["GET","POST"], rateLimit: nil, proxyEnabled: true)]
        try JSONEncoder().encode(routes).write(to: file)

        let server = GatewayServer(plugins: [guardPlugin], zoneManager: nil, routeStoreURL: file)
        let port = 9139
        Task { try await server.start(port: port) }
        try await Task.sleep(nanoseconds: 100_000_000)

        // GET should pass
        let (_, gresp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/awareness/health")!)
        XCTAssertEqual((gresp as? HTTPURLResponse)?.statusCode, 200)

        // POST should be denied regardless of token
        var req = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/awareness/corpus/init")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(InitIn(corpusId: "deny1"))
        // No token -> 403 (ForbiddenError)
        let (_, r1) = try await URLSession.shared.data(for: req)
        XCTAssertEqual((r1 as? HTTPURLResponse)?.statusCode, 403)
        // Even with admin token -> 403
        let store = CredentialStore()
        let admin = try store.signJWT(subject: "c", expiresAt: Date().addingTimeInterval(3600), role: "admin")
        req.setValue("Bearer \(admin)", forHTTPHeaderField: "Authorization")
        let (_, r2) = try await URLSession.shared.data(for: req)
        XCTAssertEqual((r2 as? HTTPURLResponse)?.statusCode, 403)

        try await server.stop(); try await upstream.stop()
    }
}

