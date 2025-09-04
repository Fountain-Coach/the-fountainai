import XCTest
@testable import AwarenessService

final class QueryParamsTests: XCTestCase {
    func testNoQueryReturnsEmptyDictionary() {
        let result = AwarenessRouter.queryParams(from: "/path")
        XCTAssertTrue(result.isEmpty)
    }

    func testMultipleParametersParsedCorrectly() {
        let result = AwarenessRouter.queryParams(from: "/path?a=1&b=2")
        XCTAssertEqual(result["a"], "1")
        XCTAssertEqual(result["b"], "2")
        XCTAssertEqual(result.count, 2)
    }

    func testEmptyValuesAreIgnored() {
        let result = AwarenessRouter.queryParams(from: "/path?a=&b=2&c")
        XCTAssertNil(result["a"])
        XCTAssertEqual(result["b"], "2")
        XCTAssertNil(result["c"])
        XCTAssertEqual(result.count, 1)
    }
}
