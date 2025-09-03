import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Yams
@testable import gateway_server
@testable import AwarenessService
@testable import FountainStoreClient

final class ProxySchemaValidationHistoryTests: XCTestCase {
    @MainActor
    func testHistoryViaGatewayMatchesSchema() async throws {
        // Upstream awareness: seed baseline for history
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        await svc.ensureCollections()
        let router = AwarenessRouter(persistence: svc)
        _ = try await router.route(.init(method: "POST", path: "/corpus/init", body: try JSONEncoder().encode(InitIn(corpusId: "gwh"))))
        _ = try await router.route(.init(method: "POST", path: "/corpus/baseline", body: try JSONEncoder().encode(BaselineRequest(corpusId: "gwh", baselineId: "b1", content: "x"))))
        let upstream = NIOHTTPServer(kernel: makeAwarenessKernel(service: svc))
        let upstreamPort = try await upstream.start(port: 0)

        // Gateway route config
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("routes.json")
        struct Route: Codable { var id: String; var path: String; var target: String; var methods: [String]; var rateLimit: Int?; var proxyEnabled: Bool? }
        let routes = [Route(id: "awareness", path: "/awareness", target: "http://127.0.0.1:\(upstreamPort)", methods: ["GET","POST"], rateLimit: nil, proxyEnabled: true)]
        try JSONEncoder().encode(routes).write(to: file)

        let server = GatewayServer(plugins: [], zoneManager: nil, routeStoreURL: file)
        let port = 9140
        Task { try await server.start(port: port) }
        try await Task.sleep(nanoseconds: 100_000_000)

        let (data, resp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/awareness/corpus/history?corpus_id=gwh")!)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let text = try String(contentsOfFile: "openapi/v1/baseline-awareness.yml")
        let yaml = try Yams.load(yaml: text) as? [String: Any]
        let schemas = (yaml?["components"] as? [String: Any])?["schemas"] as? [String: Any]
        guard let hs = schemas?["HistoryEventsResponse"] as? [String: Any] else {
            return XCTFail("HistoryEventsResponse missing in spec")
        }
        XCTAssertTrue(OpenAPISchemaValidator.validate(object: obj ?? [:], against: hs))
        // Validate each event item too (against base and specific schemas)
        if let events = obj?["events"] as? [[String: Any]] {
            let he = (schemas?["HistoryEvent"] as? [String: Any]) ?? [:]
            let be = (schemas?["BaselineEvent"] as? [String: Any]) ?? [:]
            let re = (schemas?["ReflectionEvent"] as? [String: Any]) ?? [:]
            let de = (schemas?["DriftEvent"] as? [String: Any]) ?? [:]
            let pe = (schemas?["PatternsEvent"] as? [String: Any]) ?? [:]
            for item in events {
                XCTAssertTrue(OpenAPISchemaValidator.validate(object: item, against: he))
                if let t = item["type"] as? String {
                    switch t {
                    case "baseline": XCTAssertTrue(OpenAPISchemaValidator.validate(object: item, against: be))
                    case "reflection": XCTAssertTrue(OpenAPISchemaValidator.validate(object: item, against: re))
                    case "drift": XCTAssertTrue(OpenAPISchemaValidator.validate(object: item, against: de))
                    case "patterns": XCTAssertTrue(OpenAPISchemaValidator.validate(object: item, against: pe))
                    default: XCTFail("unknown event type: \(t)")
                    }
                } else { XCTFail("event missing type") }
            }
        }

        try await server.stop(); try await upstream.stop()
    }
}
