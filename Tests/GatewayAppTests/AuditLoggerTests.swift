import XCTest
@testable import SecuritySentinelGatewayPlugin

final class AuditLoggerTests: XCTestCase {
    func testSHA256Hashing() {
        let digest = Hashing.sha256Hex("hello")
        XCTAssertEqual(digest, "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
    }

    func testContextRedaction() {
        let context = ["token": "123", "apikey": "abc", "secretInfo": "shh", "other": "keep"]
        let redacted = AuditLogger.redact(context)
        XCTAssertEqual(redacted["token"], "[REDACTED]")
        XCTAssertEqual(redacted["apikey"], "[REDACTED]")
        XCTAssertEqual(redacted["secretInfo"], "[REDACTED]")
        XCTAssertEqual(redacted["other"], "keep")
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
