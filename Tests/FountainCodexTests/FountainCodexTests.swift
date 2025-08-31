import XCTest
import FountainCodex
import NIOHTTP1

final class FountainCodexTests: XCTestCase {
    func testHTTPRequestThroughCodex() {
        let req = HTTPRequest(method: "GET", path: "/", headers: [:])
        XCTAssertEqual(req.path, "/")
    }

    func testURLSessionClientError() async {
        let client = URLSessionHTTPClient()
        do {
            _ = try await client.execute(method: .GET, url: "://bad", body: nil)
            XCTFail("Expected to throw")
        } catch {
            // expected
        }
    }
}
