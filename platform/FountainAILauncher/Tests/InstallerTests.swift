import XCTest
import Foundation
@testable import FountainAiLauncher

final class InstallerTests: XCTestCase {
    func testInstallCopiesBinaries() throws {
        let fm = FileManager.default
        let product = "SampleService"
        let repoRoot = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let releaseDir = repoRoot.appendingPathComponent(".build/release")
        try fm.createDirectory(at: releaseDir, withIntermediateDirectories: true, attributes: nil)
        defer { try? fm.removeItem(at: repoRoot) }

        let sourcePath = releaseDir.appendingPathComponent(product)
        let data = "binary".data(using: .utf8)!
        fm.createFile(atPath: sourcePath.path, contents: data)

        let destDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: destDir, withIntermediateDirectories: true)
        let service = Service(name: product, binaryPath: destDir.appendingPathComponent(product).path)
        defer { try? fm.removeItem(atPath: service.binaryPath) }

        try Installer.install(services: [service], repositoryRoot: repoRoot)
        XCTAssertTrue(fm.fileExists(atPath: service.binaryPath))
        let copied = try Data(contentsOf: URL(fileURLWithPath: service.binaryPath))
        XCTAssertEqual(copied, data)
    }

    func testMissingProductThrows() throws {
        let service = Service(name: "Missing", binaryPath: "/tmp/Missing")
        let repoRoot = URL(fileURLWithPath: FileManager.default.temporaryDirectory.path)
        XCTAssertThrowsError(try Installer.install(services: [service], repositoryRoot: repoRoot)) { error in
            guard case InstallerError.missingProduct(let product) = error else {
                return XCTFail("Expected missingProduct")
            }
            XCTAssertEqual(product, "Missing")
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
