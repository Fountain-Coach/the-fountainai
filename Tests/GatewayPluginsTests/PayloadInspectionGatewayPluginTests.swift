import XCTest
import FountainRuntime
import PayloadInspectionGatewayPlugin

final class PayloadInspectionGatewayPluginTests: XCTestCase {
    func testInspectionUsesLLM() async throws {
        let plugin = PayloadInspectionGatewayPlugin()
        let body = try JSONEncoder().encode(PayloadInspectionRequest(payload: "hi"))
        let request = HTTPRequest(method: "POST", path: "/inspect", body: body)
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 200)
    }
}
