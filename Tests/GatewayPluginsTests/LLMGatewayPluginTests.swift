import XCTest
import Foundation
import FountainRuntime
@testable import LLMGatewayPlugin

final class LLMGatewayPluginTests: XCTestCase {
    func testChatReturnsID() async throws {
        let plugin = LLMGatewayPlugin()
        let requestBody = ChatRequest(model: "gpt", messages: [MessageObject(role: "user", content: "hi")])
        let body = try JSONEncoder().encode(requestBody)
        let request = HTTPRequest(method: "POST", path: "/chat", body: body)
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 200)
        let json = try JSONSerialization.jsonObject(with: response?.body ?? Data()) as? [String: Any]
        XCTAssertNotNil(json?["id"])
    }

    func testChatInvalidBodyReturns400() async throws {
        let plugin = LLMGatewayPlugin()
        let request = HTTPRequest(method: "POST", path: "/chat", body: Data())
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 400)
    }

    func testMetricsEndpoint() async throws {
        let plugin = LLMGatewayPlugin()
        let request = HTTPRequest(method: "GET", path: "/metrics")
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 200)
        let bodyString = String(data: response?.body ?? Data(), encoding: .utf8)
        XCTAssertTrue(bodyString?.contains("llm_gateway_uptime_seconds") ?? false)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
