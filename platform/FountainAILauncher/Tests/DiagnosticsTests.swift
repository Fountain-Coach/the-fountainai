import XCTest
import Foundation
@testable import FountainAiLauncher
#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif

final class DiagnosticsTests: XCTestCase {
    func testEnvParsingLoadsVariables() throws {
        let fm = FileManager.default
        let env = "OPENAI_API_KEY=foo\nFOUNTAINSTORE_URL=http://example\nFOUNTAINSTORE_API_KEY=bar\n"
        try env.write(toFile: ".env", atomically: true, encoding: .utf8)
        defer { try? fm.removeItem(atPath: ".env") }
        for key in Diagnostics.requiredKeys { unsetenv(key) }

        try Diagnostics.loadEnv()
        XCTAssertEqual(ProcessInfo.processInfo.environment["OPENAI_API_KEY"], "foo")
        XCTAssertEqual(ProcessInfo.processInfo.environment["FOUNTAINSTORE_API_KEY"], "bar")
        XCTAssertNoThrow(try Diagnostics.validateEnv())
        for key in Diagnostics.requiredKeys { unsetenv(key) }
    }

    func testMissingRequiredKeyThrows() throws {
        let fm = FileManager.default
        let env = "OPENAI_API_KEY=foo\nFOUNTAINSTORE_URL=http://example\n"
        try env.write(toFile: ".env", atomically: true, encoding: .utf8)
        defer { try? fm.removeItem(atPath: ".env") }
        for key in Diagnostics.requiredKeys { unsetenv(key) }

        try Diagnostics.loadEnv()
        XCTAssertThrowsError(try Diagnostics.validateEnv()) { error in
            guard case DiagnosticsError.missingEnv(let key) = error else {
                return XCTFail("Expected missingEnv")
            }
            XCTAssertEqual(key, "FOUNTAINSTORE_API_KEY")
        }
        for key in Diagnostics.requiredKeys { unsetenv(key) }
    }

    func testRunSkipsMissingEnvFile() throws {
        let fm = FileManager.default
        let originalCwd = fm.currentDirectoryPath
        defer { fm.changeCurrentDirectoryPath(originalCwd) }
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        fm.changeCurrentDirectoryPath(repoRoot.path)

        setenv("OPENAI_API_KEY", "inline", 1)
        setenv("FOUNTAINSTORE_URL", "http://example", 1)
        setenv("FOUNTAINSTORE_API_KEY", "inline", 1)

        XCTAssertNoThrow(try Diagnostics.run())

        unsetenv("OPENAI_API_KEY")
        unsetenv("FOUNTAINSTORE_URL")
        unsetenv("FOUNTAINSTORE_API_KEY")
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
