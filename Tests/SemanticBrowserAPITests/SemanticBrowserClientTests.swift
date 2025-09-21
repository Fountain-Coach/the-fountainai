import XCTest
@testable import SemanticBrowserAPI
import ApiClientsCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@MainActor
final class SemanticBrowserClientTests: XCTestCase {
    override class func setUp() { URLProtocol.registerClass(MockURLProtocol.self) }
    override class func tearDown() { URLProtocol.unregisterClass(MockURLProtocol.self) }

    func testQuerySegmentsAndGetPage() async throws {
        var step = 0
        MockURLProtocol.requestHandler = { req in
            step += 1
            if req.url!.path.hasSuffix("/v1/segments") {
                let body = Data("{\"total\":1,\"items\":[{\"id\":\"s1\"}]}".utf8)
                let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
                return (resp, body)
            } else if req.url!.path.contains("/v1/pages/") {
                let body = Data("{\"id\":\"p1\"}".utf8)
                let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
                return (resp, body)
            } else {
                let resp = HTTPURLResponse(url: req.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
                return (resp, Data())
            }
        }
        let client = SemanticBrowserClient(baseURL: URL(string: "http://semantic-browser.local")!)
        let segs = try await client.querySegments(q: "swift")
        XCTAssertEqual(segs.total, 1)
        XCTAssertEqual(segs.items.first?.id, "s1")
        let page = try await client.getPage(id: "p1")
        XCTAssertEqual(page.id, "p1")
    }

    func testExportArtifacts() async throws {
        MockURLProtocol.requestHandler = { req in
            XCTAssertTrue(req.url!.absoluteString.contains("format=snapshot.text"))
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"text/plain"])!
            return (resp, Data("hello".utf8))
        }
        let client = SemanticBrowserClient(baseURL: URL(string: "http://semantic-browser.local")!)
        let data = try await client.exportArtifacts(pageId: "p1", format: "snapshot.text")
        XCTAssertEqual(String(data: data, encoding: .utf8), "hello")
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
