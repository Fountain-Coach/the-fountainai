import XCTest
@testable import ToolServerService

final class ToolServerRouterTests: XCTestCase {
    private func makeRouter() -> Router {
        Router()
    }

    func testUnmappedRouteReturns404() async throws {
        let router = makeRouter()
        let resp = try await router.route(.init(method: "POST", path: "/unknown"))
        XCTAssertEqual(resp.status, 404)
        XCTAssertEqual(resp.headers["Content-Type"], "text/plain")
        XCTAssertEqual(String(data: resp.body, encoding: .utf8), "Not Found")
    }

    func testUnsupportedMethodReturns405() async throws {
        let router = makeRouter()
        let resp = try await router.route(.init(method: "GET", path: "/ffmpeg"))
        XCTAssertEqual(resp.status, 405)
        XCTAssertEqual(resp.headers["Content-Type"], "text/plain")
        XCTAssertEqual(resp.headers["Allow"], "POST")
        XCTAssertEqual(String(data: resp.body, encoding: .utf8), "Method Not Allowed")
    }
}
