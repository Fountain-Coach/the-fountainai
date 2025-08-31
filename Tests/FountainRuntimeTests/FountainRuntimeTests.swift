import XCTest
import Foundation
import FountainRuntime
import NIOHTTP1

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
}
