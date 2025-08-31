import XCTest
import FountainRuntime
import PayloadInspectionGatewayPlugin

final class PayloadInspectionGatewayPluginTests: XCTestCase {
    func testRejectsOversizedPayload() async throws {
        let plugin = PayloadInspectionGatewayPlugin(maxPayloadBytes: 10)
        let large = String(repeating: "a", count: 20)
        let body = try JSONEncoder().encode(PayloadInspectionRequest(payload: large))
        let request = HTTPRequest(method: "POST", path: "/inspect", body: body)
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 413)
    }

    func testAcceptsPayloadWithinLimit() async throws {
        let plugin = PayloadInspectionGatewayPlugin(maxPayloadBytes: 10)
        let body = try JSONEncoder().encode(PayloadInspectionRequest(payload: "hi"))
        let request = HTTPRequest(method: "POST", path: "/inspect", body: body)
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 200)
    }
}
