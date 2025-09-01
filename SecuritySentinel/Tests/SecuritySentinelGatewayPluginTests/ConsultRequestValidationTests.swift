import XCTest
@testable import SecuritySentinelGatewayPluginModule

final class ConsultRequestValidationTests: XCTestCase {
    func testValidSummaryPasses() throws {
        let req = ConsultRequest(summary: "do stuff", context: "ctx")
        XCTAssertNoThrow(try req.validate())
    }

    func testEmptySummaryThrows() {
        let req = ConsultRequest(summary: "   ", context: "ctx")
        XCTAssertThrowsError(try req.validate())
    }

    func testTooLongSummaryThrows() {
        let long = String(repeating: "a", count: 1001)
        let req = ConsultRequest(summary: long, context: "ctx")
        XCTAssertThrowsError(try req.validate())
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
