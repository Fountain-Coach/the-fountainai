import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Yams
@testable import AwarenessService
@testable import BootstrapService
@testable import FountainStoreClient
@testable import FountainRuntime

final class RuntimeSchemaValidationTests: XCTestCase {
    @MainActor
    func testSummaryMatchesYAMLSchema() async throws {
        // Start awareness via NIO kernel
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        await svc.ensureCollections()
        let router = AwarenessRouter(persistence: svc)
        _ = try await router.route(.init(method: "POST", path: "/corpus/init", body: try JSONEncoder().encode(InitIn(corpusId: "cspec"))))
        let _ = try await router.route(.init(method: "POST", path: "/corpus/baseline", body: try JSONEncoder().encode(BaselineRequest(corpusId: "cspec", baselineId: "b1", content: "x"))))

        // Call /corpus/summary/{corpus_id}
        let kernel = makeAwarenessKernel(service: svc)
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)
        let (data, resp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/corpus/summary/cspec")!)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Load YAML schema
        let url = URL(fileURLWithPath: "openapi/v1/baseline-awareness.yml")
        let text = try String(contentsOf: url)
        let yaml = try Yams.load(yaml: text) as? [String: Any]
        let hist = ((yaml?["components"] as? [String: Any])?["schemas"] as? [String: Any])?["HistorySummaryResponse"] as? [String: Any]
        XCTAssertNotNil(hist)
        XCTAssertTrue(OpenAPISchemaValidator.validate(object: obj ?? [:], against: hist!))
        try await server.stop()
    }

    @MainActor
    func testReflectionsSummaryMatchesSchema() async throws {
        // Start awareness via NIO kernel; seed a reflection
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        await svc.ensureCollections()
        let router = AwarenessRouter(persistence: svc)
        _ = try await router.route(.init(method: "POST", path: "/corpus/init", body: try JSONEncoder().encode(InitIn(corpusId: "rfx"))))
        _ = try await router.route(.init(method: "POST", path: "/corpus/reflections", body: try JSONEncoder().encode(ReflectionRequest(corpusId: "rfx", reflectionId: "r1", question: "q", content: "a"))))

        let kernel = makeAwarenessKernel(service: svc)
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)
        let (data, resp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/corpus/reflections/rfx")!)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let url = URL(fileURLWithPath: "openapi/v1/baseline-awareness.yml")
        let text = try String(contentsOf: url)
        let yaml = try Yams.load(yaml: text) as? [String: Any]
        let schemas = (yaml?["components"] as? [String: Any])?["schemas"] as? [String: Any]
        guard let reflSummary = schemas?["ReflectionSummaryResponse"] as? [String: Any] else {
            return XCTFail("ReflectionSummaryResponse missing in spec")
        }
        XCTAssertTrue(OpenAPISchemaValidator.validate(object: obj ?? [:], against: reflSummary))
        try await server.stop()
    }


    @MainActor
    func testBootstrapRoleDefaultsMatchesSchema() async throws {
        // Start bootstrap via kernel and call /bootstrap/roles/seed
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        await svc.ensureCollections()
        let kernel = makeBootstrapKernel(service: svc)
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)
        var req = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/bootstrap/roles/seed")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(RoleInitRequest(corpusId: "crole"))
        let (data, resp) = try await URLSession.shared.data(for: req)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Load RoleDefaults schema
        let url = URL(fileURLWithPath: "openapi/v1/bootstrap.yml")
        let text = try String(contentsOf: url)
        let yaml = try Yams.load(yaml: text) as? [String: Any]
        let schemas = (yaml?["components"] as? [String: Any])?["schemas"] as? [String: Any]
        guard let roleDefaults = schemas?["RoleDefaults"] as? [String: Any] else {
            return XCTFail("RoleDefaults missing in spec")
        }
        XCTAssertTrue(OpenAPISchemaValidator.validate(object: obj ?? [:], against: roleDefaults))
        try await server.stop()
    }

    @MainActor
    func testBootstrapInitOutMatchesSchema() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        await svc.ensureCollections()
        let kernel = makeBootstrapKernel(service: svc)
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)
        var req = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/bootstrap/corpus/init")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(InitIn(corpusId: "cinit"))
        let (data, resp) = try await URLSession.shared.data(for: req)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let url = URL(fileURLWithPath: "openapi/v1/bootstrap.yml")
        let text = try String(contentsOf: url)
        let yaml = try Yams.load(yaml: text) as? [String: Any]
        let schemas = (yaml?["components"] as? [String: Any])?["schemas"] as? [String: Any]
        guard let initOut = schemas?["InitOut"] as? [String: Any] else {
            return XCTFail("InitOut missing in spec")
        }
        XCTAssertTrue(OpenAPISchemaValidator.validate(object: obj ?? [:], against: initOut))
        try await server.stop()
    }


    @MainActor
    func testHistoryHasTotalAndEvents() async throws {
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        await svc.ensureCollections()
        let router = AwarenessRouter(persistence: svc)
        _ = try await router.route(.init(method: "POST", path: "/corpus/init", body: try JSONEncoder().encode(InitIn(corpusId: "histx"))))
        _ = try await router.route(.init(method: "POST", path: "/corpus/baseline", body: try JSONEncoder().encode(BaselineRequest(corpusId: "histx", baselineId: "b1", content: "x"))))
        let kernel = makeAwarenessKernel(service: svc)
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)
        let (data, resp) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)/corpus/history?corpus_id=histx")!)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(obj?["total"]) ; XCTAssertTrue(obj?["total"] is Int)
        XCTAssertNotNil(obj?["events"]) ; XCTAssertTrue(obj?["events"] is [Any])
        try await server.stop()
    }
}
