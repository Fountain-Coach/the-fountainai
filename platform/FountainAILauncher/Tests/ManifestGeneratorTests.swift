import XCTest
import Foundation
@testable import FountainAiLauncher
import Crypto

final class ManifestGeneratorTests: XCTestCase {
    func testGeneratedManifestContainsHashAndPermissions() throws {
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
        let binary = tmp.appendingPathComponent("svc")
        let data = "hello".data(using: .utf8)!
        fm.createFile(atPath: binary.path, contents: data)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binary.path)

        let service = Service(name: "Svc", binaryPath: binary.path)
        let manifestURL = tmp.appendingPathComponent("manifest.json")
        try ManifestGenerator.generate(services: [service], url: manifestURL)

        let entries = try JSONDecoder().decode([ServiceManifestEntry].self, from: Data(contentsOf: manifestURL))
        XCTAssertEqual(entries.count, 1)
        let entry = entries[0]
        XCTAssertEqual(entry.permissions, 0o755)
        let expectedHash = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(entry.sha256, expectedHash)
    }

    func testVerifyThrowsOnHashMismatch() throws {
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
        let binary = tmp.appendingPathComponent("svc")
        fm.createFile(atPath: binary.path, contents: "orig".data(using: .utf8))
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binary.path)
        let service = Service(name: "Svc", binaryPath: binary.path)
        let manifestURL = tmp.appendingPathComponent("manifest.json")
        try ManifestGenerator.generate(services: [service], url: manifestURL)

        try "tamper".data(using: .utf8)!.write(to: binary)
        let supervisor = Supervisor(launcherSignature: "sig")
        XCTAssertThrowsError(try supervisor.verify(services: [service], manifestURL: manifestURL)) { error in
            guard case ManifestError.hashMismatch(let name) = error else {
                return XCTFail("Expected hashMismatch")
            }
            XCTAssertEqual(name, "Svc")
        }
    }

    func testVerifyThrowsOnPermissionMismatch() throws {
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
        let binary = tmp.appendingPathComponent("svc")
        fm.createFile(atPath: binary.path, contents: "orig".data(using: .utf8))
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binary.path)
        let service = Service(name: "Svc", binaryPath: binary.path)
        let manifestURL = tmp.appendingPathComponent("manifest.json")
        try ManifestGenerator.generate(services: [service], url: manifestURL)

        try fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: binary.path)
        let supervisor = Supervisor(launcherSignature: "sig")
        XCTAssertThrowsError(try supervisor.verify(services: [service], manifestURL: manifestURL)) { error in
            guard case ManifestError.permissionMismatch(let name) = error else {
                return XCTFail("Expected permissionMismatch")
            }
            XCTAssertEqual(name, "Svc")
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
