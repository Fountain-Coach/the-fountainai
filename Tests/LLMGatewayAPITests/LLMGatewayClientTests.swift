import XCTest
@testable import LLMGatewayAPI
import ApiClientsCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@MainActor
final class LLMGatewayClientTests: XCTestCase {
    override class func setUp() { URLProtocol.registerClass(MockURLProtocol.self) }
    override class func tearDown() { URLProtocol.unregisterClass(MockURLProtocol.self) }

    func testChatSendsBody() async throws {
        MockURLProtocol.requestHandler = { req in
            XCTAssertEqual(req.httpMethod, "POST")
            XCTAssertEqual(req.url?.path, "/chat")
            let payload = try! JSONSerialization.jsonObject(with: req.httpBody ?? Data()) as! [String: Any]
            XCTAssertEqual(payload["model"] as? String, "gpt-4o-mini")
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
            return (resp, Data("{}".utf8))
        }
        let client = LLMGatewayClient(baseURL: URL(string: "http://llm.local/api/v1")!)
        _ = try await client.chat(.init(model: "gpt-4o-mini", messages: [.init(role: "user", content: "hi")]))
    }
}

@MainActor
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else { return }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}
