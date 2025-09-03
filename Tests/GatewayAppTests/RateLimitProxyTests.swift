import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import gateway_server
@testable import AwarenessService
@testable import FountainStoreClient
@testable import RateLimiterGatewayPlugin

final class RateLimitProxyTests: XCTestCase {
    @MainActor
    func test429OnSecondRequest() async throws {
        // Upstream awareness
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        await svc.ensureCollections()
        let awarenessKernel = makeAwarenessKernel(service: svc)
        let upstream = NIOHTTPServer(kernel: awarenessKernel)
        let upstreamPort = try await upstream.start(port: 0)

        // Routes with very low limit
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("routes.json")
        struct Route: Codable { var id: String; var path: String; var target: String; var methods: [String]; var rateLimit: Int?; var proxyEnabled: Bool? }
        let routes = [Route(id: "awareness", path: "/awareness", target: "http://127.0.0.1:\(upstreamPort)", methods: ["GET","POST"], rateLimit: 1, proxyEnabled: true)]
        try JSONEncoder().encode(routes).write(to: file)

        // Gateway with rate limiter enabled
        let limiter = RateLimiterGatewayPlugin(defaultLimit: 1)
        let server = GatewayServer(plugins: [], zoneManager: nil, routeStoreURL: file, certificatePath: nil, rateLimiter: limiter)
        let port = 9132
        Task { try await server.start(port: port) }
        try await Task.sleep(nanoseconds: 100_000_000)

        // First request should pass
        let url = URL(string: "http://127.0.0.1:\(port)/awareness/health")!
        let (_, r1) = try await URLSession.shared.data(from: url)
        XCTAssertEqual((r1 as? HTTPURLResponse)?.statusCode, 200)
        // Second immediately should hit 429
        let (_, r2) = try await URLSession.shared.data(from: url)
        XCTAssertEqual((r2 as? HTTPURLResponse)?.statusCode, 429)

        try await server.stop(); try await upstream.stop()
    }

    @MainActor
    func testPerRouteOverridesAndMetrics() async throws {
        let upstreamKernel = HTTPKernel { _ in HTTPResponse(status: 200) }
        let upstream = NIOHTTPServer(kernel: upstreamKernel)
        let upstreamPort = try await upstream.start(port: 0)

        struct Route: Codable { var id: String; var path: String; var target: String; var methods: [String]; var rateLimit: Int?; var proxyEnabled: Bool? }
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("routes.json")
        let routes = [
            Route(id: "r1", path: "/one", target: "http://127.0.0.1:\(upstreamPort)", methods: ["GET"], rateLimit: 1, proxyEnabled: true),
            Route(id: "r2", path: "/two", target: "http://127.0.0.1:\(upstreamPort)", methods: ["GET"], rateLimit: 2, proxyEnabled: true)
        ]
        try JSONEncoder().encode(routes).write(to: file)

        await DNSMetrics.shared.reset()
        let limiter = RateLimiterGatewayPlugin(defaultLimit: 1)
        let server = GatewayServer(plugins: [], zoneManager: nil, routeStoreURL: file, certificatePath: nil, rateLimiter: limiter)
        let port = 9133
        Task { try await server.start(port: port) }
        try await Task.sleep(nanoseconds: 100_000_000)

        let before = await GatewayRequestMetrics.shared.snapshot()

        let url1 = URL(string: "http://127.0.0.1:\(port)/one/x")!
        let (_, a1) = try await URLSession.shared.data(from: url1)
        XCTAssertEqual((a1 as? HTTPURLResponse)?.statusCode, 200)
        let (_, a2) = try await URLSession.shared.data(from: url1)
        XCTAssertEqual((a2 as? HTTPURLResponse)?.statusCode, 429)

        let url2 = URL(string: "http://127.0.0.1:\(port)/two/x")!
        let (_, b1) = try await URLSession.shared.data(from: url2)
        XCTAssertEqual((b1 as? HTTPURLResponse)?.statusCode, 200)
        let (_, b2) = try await URLSession.shared.data(from: url2)
        XCTAssertEqual((b2 as? HTTPURLResponse)?.statusCode, 200)
        let (_, b3) = try await URLSession.shared.data(from: url2)
        XCTAssertEqual((b3 as? HTTPURLResponse)?.statusCode, 429)

        let metricsURL = URL(string: "http://127.0.0.1:\(port)/metrics")!
        let (data, _) = try await URLSession.shared.data(from: metricsURL)
        let metrics = try JSONDecoder().decode([String: Int].self, from: data)
        XCTAssertEqual(metrics["gateway_rate_limit_allowed_total"], 3)
        XCTAssertEqual(metrics["gateway_rate_limit_throttled_total"], 2)

        let after = await GatewayRequestMetrics.shared.snapshot()
        let key200 = "gateway_responses_status_200_total"
        let key429 = "gateway_responses_status_429_total"
        XCTAssertEqual((after[key200] ?? 0) - (before[key200] ?? 0), 3)
        XCTAssertEqual((after[key429] ?? 0) - (before[key429] ?? 0), 2)

        try await server.stop(); try await upstream.stop()
    }
}

