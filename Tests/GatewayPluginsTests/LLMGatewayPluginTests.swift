import XCTest
import Foundation
import FountainRuntime
@testable import LLMGatewayPlugin

final class LLMGatewayPluginTests: XCTestCase {
    func testChatIncludesCoT() async throws {
        let plugin = LLMGatewayPlugin()
        let requestBody = ChatRequest(model: "gpt", messages: [MessageObject(role: "user", content: "hi")], include_cot: true)
        let body = try JSONEncoder().encode(requestBody)
        let request = HTTPRequest(method: "POST", path: "/chat", body: body)
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 200)
        let json = try JSONSerialization.jsonObject(with: response?.body ?? Data()) as? [String: Any]
        XCTAssertNotNil(json?["id"])
        XCTAssertNotNil(json?["cot"])
    }

    func testChatInvalidBodyReturns400() async throws {
        let plugin = LLMGatewayPlugin()
        let request = HTTPRequest(method: "POST", path: "/chat", body: Data())
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 400)
    }

    func testGetChatCotRedactsForDeveloper() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        try "{\"id\":\"123\",\"cot\":\"first middle last\"}\n".write(to: tempURL, atomically: true, encoding: .utf8)
        let plugin = LLMGatewayPlugin(cotLogURL: tempURL)
        let request = HTTPRequest(method: "GET", path: "/chat/123/cot", headers: ["X-User-Role": "developer"])
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 200)
        let json = try JSONSerialization.jsonObject(with: response?.body ?? Data()) as? [String: String]
        XCTAssertEqual(json?["cot"], "first [REDACTED] last")
    }

    func testGetChatCotSummaryForDefaultRole() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        try "{\"id\":\"123\",\"cot\":\"first middle last\"}\n".write(to: tempURL, atomically: true, encoding: .utf8)
        let plugin = LLMGatewayPlugin(cotLogURL: tempURL)
        let request = HTTPRequest(method: "GET", path: "/chat/123/cot")
        let response = try await plugin.router.route(request)
        XCTAssertEqual(response?.status, 200)
        let json = try JSONSerialization.jsonObject(with: response?.body ?? Data()) as? [String: String]
        XCTAssertEqual(json?["cot_summary"], "first mi...")
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
