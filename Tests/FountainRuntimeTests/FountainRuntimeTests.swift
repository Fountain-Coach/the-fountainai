import XCTest
import Foundation
import FountainRuntime
import NIOHTTP1
import FountainStoreClient

final class FountainRuntimeTests: XCTestCase {
    func testHTTPRequestInitialization() {
        let req = HTTPRequest(method: "GET", path: "/test", headers: ["A": "B"], body: Data("hi".utf8))
        XCTAssertEqual(req.method, "GET")
        XCTAssertEqual(req.path, "/test")
        XCTAssertEqual(req.headers["A"], "B")
    }

    func testHTTPResponseDefault() {
        let resp = HTTPResponse()
        XCTAssertEqual(resp.status, 200)
        XCTAssertTrue(resp.headers.isEmpty)
    }

    func testHTTPResponseInitializerStoresValues() {
        let body = Data("ok".utf8)
        let resp = HTTPResponse(status: 201, headers: ["Content-Type": "text/plain"], body: body)
        XCTAssertEqual(resp.status, 201)
        XCTAssertEqual(resp.headers["Content-Type"], "text/plain")
        XCTAssertEqual(String(data: resp.body, encoding: .utf8), "ok")
    }

    func testURLSessionHTTPClientBadURLThrows() async {
        let client = URLSessionHTTPClient()
        do {
            _ = try await client.execute(method: .GET, url: "://bad", body: nil)
            XCTFail("Expected to throw")
        } catch {
            // expected error
        }
    }

    func testHTTPKernelMapsCapabilityError() async throws {
        let kernel = HTTPKernel { _ in throw PersistenceError.notSupported(need: "query.fullText") }
        let resp = try await kernel.handle(HTTPRequest(method: "GET", path: "/"))
        XCTAssertEqual(resp.status, 400)
        let body = try JSONDecoder().decode([String: String].self, from: resp.body)
        XCTAssertEqual(body["need"], "query.fullText")
        XCTAssertEqual(body["error"], "not-supported")
    }

    func testHTTPKernelHandlesRequest() async throws {
        let kernel = HTTPKernel { req in
            XCTAssertEqual(req.path, "/ok")
            return HTTPResponse(status: 201, headers: ["X-Test": "yes"], body: Data("ok".utf8))
        }
        let resp = try await kernel.handle(HTTPRequest(method: "GET", path: "/ok"))
        XCTAssertEqual(resp.status, 201)
        XCTAssertEqual(resp.headers["X-Test"], "yes")
        XCTAssertEqual(String(data: resp.body, encoding: .utf8), "ok")
    }

    func testHTTPRequestMutation() {
        var req = HTTPRequest(method: "POST", path: "/submit")
        req.headers["Content-Type"] = "text/plain"
        req.body = Data("body".utf8)
        XCTAssertEqual(req.headers["Content-Type"], "text/plain")
        XCTAssertEqual(String(data: req.body, encoding: .utf8), "body")
    }
}
