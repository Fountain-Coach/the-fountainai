import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Yams
@testable import gateway_server
@testable import AwarenessService
@testable import FountainStoreClient

final class ProxySchemaValidationTests: XCTestCase {
    @MainActor
    func testAwarenessSummaryViaGatewayMatchesSchema() async throws {
        // Upstream awareness
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        await svc.ensureCollections()
        let router = AwarenessRouter(persistence: svc)
        _ = try await router.route(.init(method: "POST", path: "/corpus/init", body: try JSONEncoder().encode(InitIn(corpusId: "gwspec"))))
        _ = try await router.route(.init(method: "POST", path: "/corpus/baseline", body: try JSONEncoder().encode(BaselineRequest(corpusId: "gwspec", baselineId: "b1", content: "x"))))
        let upstream = NIOHTTPServer(kernel: makeAwarenessKernel(service: svc))
        let upstreamPort = try await upstream.start(port: 0)

        // Gateway routes file
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("routes.json")
        struct Route: Codable { var id: String; var path: String; var target: String; var methods: [String]; var rateLimit: Int?; var proxyEnabled: Bool? }
        let routes = [Route(id: "awareness", path: "/awareness", target: "http://127.0.0.1:\(upstreamPort)", methods: ["GET","POST"], rateLimit: nil, proxyEnabled: true)]
        try JSONEncoder().encode(routes).write(to: file)

        let server = GatewayServer(plugins: [], zoneManager: nil, routeStoreURL: file)
        let port = 9134
        Task { try await server.start(port: port) }
        try await Task.sleep(nanoseconds: 100_000_000)

        let (data, resp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/awareness/corpus/summary/gwspec")!)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let text = try String(contentsOfFile: "openapi/v1/baseline-awareness.yml")
        let yaml = try Yams.load(yaml: text) as? [String: Any]
        let schemas = (yaml?["components"] as? [String: Any])?["schemas"] as? [String: Any]
        guard let hist = schemas?["HistorySummaryResponse"] as? [String: Any] else {
            return XCTFail("HistorySummaryResponse missing in spec")
        }
        XCTAssertTrue(OpenAPISchemaValidator.validate(object: obj ?? [:], against: hist))

        try await server.stop(); try await upstream.stop()
    }
}

