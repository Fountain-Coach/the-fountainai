import XCTest
import Foundation
import Yams
@testable import AwarenessService
@testable import BootstrapService
@testable import FountainStoreClient
@testable import RoleHealthCheckGatewayPlugin
import FountainRuntime

final class OperationIdRouteTests: XCTestCase {
    // Build minimal valid bodies per operation for Awareness
    private func awarenessBody(for path: String) throws -> Data? {
        switch path {
        case "/corpus/init":
            return try JSONEncoder().encode(InitIn(corpusId: "co1"))
        case "/corpus/baseline":
            return try JSONEncoder().encode(BaselineRequest(corpusId: "co1", baselineId: "b1", content: "x"))
        case "/corpus/drift":
            return try JSONEncoder().encode(DriftRequest(corpusId: "co1", driftId: "d1", content: "x"))
        case "/corpus/patterns":
            return try JSONEncoder().encode(PatternsRequest(corpusId: "co1", patternsId: "p1", content: "x"))
        case "/corpus/reflections":
            return try JSONEncoder().encode(ReflectionRequest(corpusId: "co1", reflectionId: "r1", question: "q", content: "a"))
        default:
            return nil
        }
    }

    func testAwarenessOperationIdsReachable() async throws {
        // Load OpenAPI YAML
        let text = try String(contentsOfFile: "openapi/v1/baseline-awareness.yml")
        let yaml = try Yams.load(yaml: text) as? [String: Any]
        let paths = yaml?["paths"] as? [String: Any] ?? [:]
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        await svc.ensureCollections()
        let router = AwarenessRouter(persistence: svc)

        for (path, mapAny) in paths {
            guard let methods = mapAny as? [String: Any] else { continue }
            for (m, opAny) in methods {
                guard let op = opAny as? [String: Any], op["operationId"] is String else { continue }
                let method = m.uppercased()
                // Minimal handling: send proper body for POSTs when needed
                let body = try awarenessBody(for: path)
                let req = AwarenessService.HTTPRequest(method: method, path: path, body: body ?? Data())
                let resp = try await router.route(req)
                // Allow 200, 204, 400/422 for validation, but not 404
                XCTAssertNotEqual(resp.status, 404, "\(method) \(path) not routed for awareness")
            }
        }
    }

    private func bootstrapBody(for path: String) throws -> Data? {
        switch path {
        case "/bootstrap/corpus/init":
            return try JSONEncoder().encode(BootstrapService.InitIn(corpusId: "co2"))
        case "/bootstrap/roles/seed", "/bootstrap/roles":
            return try JSONEncoder().encode(RoleInitRequest(corpusId: "co2"))
        case "/bootstrap/baseline":
            return try JSONEncoder().encode(BaselineIn(corpusId: "co2", baselineId: "b2", content: "x"))
        default:
            return nil
        }
    }

    func testBootstrapOperationIdsReachable() async throws {
        let text = try String(contentsOfFile: "openapi/v1/bootstrap.yml")
        let yaml = try Yams.load(yaml: text) as? [String: Any]
        let paths = yaml?["paths"] as? [String: Any] ?? [:]
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        await svc.ensureCollections()
        let router = BootstrapRouter(persistence: svc)
        for (path, mapAny) in paths {
            guard let methods = mapAny as? [String: Any] else { continue }
            for (m, opAny) in methods {
                guard let op = opAny as? [String: Any], op["operationId"] is String else { continue }
                let method = m.uppercased()
                let body = try bootstrapBody(for: path)
                let req = BootstrapService.HTTPRequest(method: method, path: path, body: body ?? Data())
                let resp = try await router.route(req)
                XCTAssertNotEqual(resp.status, 404, "\(method) \(path) not routed for bootstrap")
            }
        }
    }

    private func roleHealthCheckBody(for path: String) throws -> Data? {
        switch path {
        case "/role-health-check/reflect", "/role-health-check/promote":
            return try JSONEncoder().encode(RoleHealthCheckRequest(corpusId: "c1", roleName: "r"))
        default:
            return nil
        }
    }

    func testRoleHealthCheckOperationIdsReachable() async throws {
        let text = try String(contentsOfFile: "openapi/v1/role-health-check-gateway.yml")
        let yaml = try Yams.load(yaml: text) as? [String: Any]
        let paths = yaml?["paths"] as? [String: Any] ?? [:]
        let plugin = RoleHealthCheckGatewayPlugin()
        for (path, mapAny) in paths {
            guard let methods = mapAny as? [String: Any] else { continue }
            for (m, opAny) in methods {
                guard let op = opAny as? [String: Any], op["operationId"] is String else { continue }
                let method = m.uppercased()
                let body = try roleHealthCheckBody(for: path)
                let req = HTTPRequest(method: method, path: path, body: body ?? Data())
                let resp = try await plugin.router.route(req)
                XCTAssertNotNil(resp, "\(method) \(path) not routed for role health check")
                XCTAssertNotEqual(resp?.status, 404, "\(method) \(path) not routed for role health check")
            }
        }
    }
}

