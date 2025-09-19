import XCTest
import Foundation
@testable import FountainAiLauncher
#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif

final class BuilderTests: XCTestCase {
    func testBuildWritesSignature() throws {
        let fm = FileManager.default
        let originalCwd = fm.currentDirectoryPath
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // BuilderTests.swift
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // FountainAILauncher
            .deletingLastPathComponent() // platform
        fm.changeCurrentDirectoryPath(repoRoot.path)
        defer { fm.changeCurrentDirectoryPath(originalCwd) }

        let sigURL = repoRoot.appendingPathComponent("libs/LauncherSignature/Signature.swift")
        let original = try String(contentsOf: sigURL, encoding: .utf8)
        defer { try? original.write(to: sigURL, atomically: true, encoding: .utf8) }

        try Builder.build(services: [], signature: "test-sig", repositoryRoot: repoRoot)
        let content = try String(contentsOf: sigURL, encoding: .utf8)
        XCTAssertTrue(content.contains("test-sig"))
    }

    func testBuildThrowsOnNonZeroExit() throws {
        let fm = FileManager.default
        let originalCwd = fm.currentDirectoryPath
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        fm.changeCurrentDirectoryPath(repoRoot.path)
        defer { fm.changeCurrentDirectoryPath(originalCwd) }

        let sigURL = repoRoot.appendingPathComponent("libs/LauncherSignature/Signature.swift")
        let originalSig = try String(contentsOf: sigURL, encoding: .utf8)
        defer { try? originalSig.write(to: sigURL, atomically: true, encoding: .utf8) }

        let service = Service(name: "Demo", binaryPath: "/tmp/Nonexistent")
        XCTAssertThrowsError(try Builder.build(services: [service], signature: "sig", repositoryRoot: repoRoot)) { error in
            guard case BuilderError.buildFailed(let product) = error else {
                return XCTFail("Expected buildFailed, got \(error)")
            }
            XCTAssertEqual(product, "Nonexistent")
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
