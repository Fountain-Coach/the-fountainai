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

    func testMissingBodyReturns400() async throws {
        let plugin = PayloadInspectionGatewayPlugin()
        let request = HTTPRequest(method: "POST", path: "/inspect")
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 400)
    }

    func testPayloadExceedingMaxSizeReturns413() async throws {
        let plugin = PayloadInspectionGatewayPlugin(maxPayloadBytes: 4)
        let body = try JSONEncoder().encode(PayloadInspectionRequest(payload: "12345"))
        let request = HTTPRequest(method: "POST", path: "/inspect", body: body)
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 413)
    }

    func testLLMFailureFallsBack() async throws {
        let previous = getenv("LLM_GATEWAY_URL").map { String(cString: $0) }
        setenv("LLM_GATEWAY_URL", "http://localhost:9/chat", 1)
        defer {
            if let previous {
                setenv("LLM_GATEWAY_URL", previous, 1)
            } else {
                unsetenv("LLM_GATEWAY_URL")
            }
        }
        let plugin = PayloadInspectionGatewayPlugin()
        let body = try JSONEncoder().encode(PayloadInspectionRequest(payload: "hi"))
        let request = HTTPRequest(method: "POST", path: "/inspect", body: body)
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 200)
        XCTAssertEqual(response?.body ?? Data(), Data("{}".utf8))
    }
}
