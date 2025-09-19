import XCTest
@testable import FountainRuntime
import FountainStoreClient
@testable import PlannerService
@testable import BootstrapService
@testable import ToolsFactoryService
@testable import gateway_server
@testable import openapi_curator_service

final class SystemSmokeTests: XCTestCase {
    func testPersistMetrics() async throws {
        let client = FountainStoreClient(client: EmbeddedFountainStoreClient())
        let kernel = makePersistKernel(service: client)
        let resp = try await kernel.handle(HTTPRequest(method: "GET", path: "/metrics"))
        XCTAssertEqual(resp.status, 200)
        XCTAssertEqual(resp.headers["Content-Type"], "text/plain")
    }

    func testPlannerMetrics() async throws {
        let client = FountainStoreClient(client: EmbeddedFountainStoreClient())
        let kernel = makePlannerKernel(service: client)
        let resp = try await kernel.handle(HTTPRequest(method: "GET", path: "/metrics"))
        XCTAssertEqual(resp.status, 200)
        XCTAssertEqual(resp.headers["Content-Type"], "text/plain")
    }

    func testBootstrapMetrics() async throws {
        let client = FountainStoreClient(client: EmbeddedFountainStoreClient())
        let kernel = makeBootstrapKernel(service: client)
        let resp = try await kernel.handle(HTTPRequest(method: "GET", path: "/metrics"))
        XCTAssertEqual(resp.status, 200)
        XCTAssertEqual(resp.headers["Content-Type"], "text/plain")
    }

    func testToolsFactoryMetrics() async throws {
        let client = FountainStoreClient(client: EmbeddedFountainStoreClient())
        // Minimal manifest
        let manifest = ToolManifest(image: .init(name: "", tarball: "", sha256: "", qcow2: "", qcow2_sha256: ""), tools: [:], operations: [])
        let kernel = makeToolsFactoryKernel(service: client, adapters: [:], manifest: manifest)
        let resp = try await kernel.handle(HTTPRequest(method: "GET", path: "/metrics"))
        XCTAssertEqual(resp.status, 200)
        XCTAssertEqual(resp.headers["Content-Type"], "text/plain")
    }

    @MainActor
    func testGatewayMetrics() async throws {
        let gw = GatewayServer()
        let resp = await gw.gatewayMetrics()
        XCTAssertEqual(resp.status, 200)
        XCTAssertEqual(resp.headers["Content-Type"], "application/json")
    }

    func testOpenAPICuratorMetrics() async throws {
        let resp = await metrics_metrics_get()
        XCTAssertEqual(resp.status, 200)
        XCTAssertEqual(resp.headers["Content-Type"], "text/plain")
    }
}

