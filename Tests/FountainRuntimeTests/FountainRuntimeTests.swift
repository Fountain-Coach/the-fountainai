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
}
