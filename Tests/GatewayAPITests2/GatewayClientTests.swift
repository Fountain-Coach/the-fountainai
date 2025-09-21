import XCTest
@testable import GatewayAPI
import ApiClientsCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@MainActor
final class GatewayClientTests2: XCTestCase {
    override class func setUp() {
        URLProtocol.registerClass(MockURLProtocol.self)
    }
    override class func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
    }

    func testHealth() async throws {
        MockURLProtocol.requestHandler = { req in
            XCTAssertEqual(req.url?.path, "/health")
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            let body = Data("{\"status\":\"ok\"}".utf8)
            return (resp, body)
        }
        let cfg = URLSessionConfiguration.default
        cfg.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: cfg)
        let client = GatewayClient(baseURL: URL(string: "http://gateway.local")!)
        // Swap internal session via KVC is not possible; instead rely on registered protocol class
        let val = try await client.health()
        if case let .object(obj) = val { XCTAssertEqual((obj["status"]), .string("ok")) } else { XCTFail("bad json") }
        _ = session // silence unused
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
