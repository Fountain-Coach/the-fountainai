import XCTest
import Foundation
@testable import FountainAiLauncher

final class InstallerTests: XCTestCase {
    func testInstallCopiesBinaries() throws {
        let fm = FileManager.default
        let product = "SampleService"
        let sourceDir = ".build/release"
        try fm.createDirectory(atPath: sourceDir, withIntermediateDirectories: true)
        let sourcePath = sourceDir + "/" + product
        let data = "binary".data(using: .utf8)!
        fm.createFile(atPath: sourcePath, contents: data)
        defer { try? fm.removeItem(atPath: sourcePath) }

        let destDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: destDir, withIntermediateDirectories: true)
        let service = Service(name: product, binaryPath: destDir.appendingPathComponent(product).path)
        defer { try? fm.removeItem(atPath: service.binaryPath) }

        try Installer.install(services: [service])
        XCTAssertTrue(fm.fileExists(atPath: service.binaryPath))
        let copied = try Data(contentsOf: URL(fileURLWithPath: service.binaryPath))
        XCTAssertEqual(copied, data)
    }

    func testMissingProductThrows() throws {
        let service = Service(name: "Missing", binaryPath: "/tmp/Missing")
        XCTAssertThrowsError(try Installer.install(services: [service])) { error in
            guard case InstallerError.missingProduct(let product) = error else {
                return XCTFail("Expected missingProduct")
            }
            XCTAssertEqual(product, "Missing")
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
