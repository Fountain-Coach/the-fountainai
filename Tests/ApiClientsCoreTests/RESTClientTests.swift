import XCTest
@testable import ApiClientsCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@MainActor
final class RESTClientTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override class func tearDown() {
        super.tearDown()
        URLProtocol.unregisterClass(MockURLProtocol.self)
    }

    func testBuildURLAndGET() async throws {
        MockURLProtocol.requestHandler = { req in
            XCTAssertEqual(req.httpMethod, "GET")
            XCTAssertTrue(req.url!.absoluteString.contains("/v1/test?foo=bar&n=1"))
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            let body = try JSONEncoder().encode(["ok": true])
            return (resp, body)
        }
        let cfg = URLSessionConfiguration.default
        cfg.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: cfg)
        let client = RESTClient(baseURL: URL(string: "http://example.local")!, defaultHeaders: ["Accept": "application/json"], session: session)
        let url = client.buildURL(path: "/v1/test", query: ["foo": "bar", "n": "1"])!
        let resp = try await client.send(APIRequest(method: .GET, url: url))
        XCTAssertEqual(resp.status, 200)
    }

    func testHTTPError() async throws {
        MockURLProtocol.requestHandler = { req in
            let resp = HTTPURLResponse(url: req.url!, statusCode: 418, httpVersion: nil, headerFields: ["Content-Type": "text/plain"])!
            return (resp, Data("teapot".utf8))
        }
        let cfg = URLSessionConfiguration.default
        cfg.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: cfg)
        let client = RESTClient(baseURL: URL(string: "http://example.local")!, session: session)
        let url = client.buildURL(path: "/x")!
        do {
            _ = try await client.send(APIRequest(method: .GET, url: url))
            XCTFail("Expected error")
        } catch {
            guard case let APIError.httpStatus(code, text) = error else { return XCTFail("Wrong error: \(error)") }
            XCTAssertEqual(code, 418)
            XCTAssertEqual(text, "teapot")
        }
    }
}

// MARK: - Helpers

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
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}

//
