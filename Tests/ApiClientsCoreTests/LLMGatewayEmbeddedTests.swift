import XCTest
@testable import LLMGatewayAPI

@MainActor
final class LLMGatewayEmbeddedTests: XCTestCase {
    func testChatEncodesModelAndMessages() async throws {
        // Pure encoding/decoding round-trip without network
        let req = ChatRequest(model: "gpt-4o-mini", messages: [.init(role: "user", content: "hi")])
        let data = try JSONEncoder().encode(req)
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(obj["model"] as? String, "gpt-4o-mini")
        let msgs = obj["messages"] as? [[String: Any]]
        XCTAssertEqual(msgs?.first?["role"] as? String, "user")
        XCTAssertEqual(msgs?.first?["content"] as? String, "hi")
    }
}

