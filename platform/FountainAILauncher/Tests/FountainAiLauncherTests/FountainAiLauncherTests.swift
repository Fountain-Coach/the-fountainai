import XCTest
@testable import FountainAiLauncher

final class FountainAiLauncherTests: XCTestCase {
    func testServiceLaunch() throws {
        let supervisor = Supervisor()
        let service = Service(name: "Echo", binaryPath: "/usr/bin/env", arguments: ["true"])
        let process = try supervisor.start(service: service)
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
    }

    func testTerminateAllStopsProcesses() throws {
        let supervisor = Supervisor()
        let service = Service(name: "Sleep", binaryPath: "/bin/sleep", arguments: ["5"])
        let process = try supervisor.start(service: service)
        XCTAssertTrue(process.isRunning)
        supervisor.terminateAll()
        process.waitUntilExit()
        XCTAssertFalse(process.isRunning)
    }

    /// Verifies the ``Service`` initializer assigns all properties correctly.
    func testServiceInitializerStoresArguments() {
        let service = Service(name: "Demo", binaryPath: "/bin/echo", arguments: ["hi"], port: 42, healthPath: "/health")
        XCTAssertEqual(service.name, "Demo")
        XCTAssertEqual(service.binaryPath, "/bin/echo")
        XCTAssertEqual(service.arguments, ["hi"])
        XCTAssertEqual(service.port, 42)
        XCTAssertEqual(service.healthPath, "/health")
        XCTAssertFalse(service.shouldRestart)
    }

    /// Ensures default initializer uses empty arguments and no health settings.
    func testServiceDefaults() {
        let service = Service(name: "Bare", binaryPath: "/bin/echo")
        XCTAssertTrue(service.arguments.isEmpty)
        XCTAssertNil(service.port)
        XCTAssertNil(service.healthPath)
        XCTAssertFalse(service.shouldRestart)
    }

    /// Decoding JSON manifest into services works.
    func testServiceDecoding() throws {
        let json = """
        [{"name":"X","binaryPath":"/bin/echo","shouldRestart":true}]
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode([Service].self, from: json)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertTrue(decoded[0].shouldRestart)
    }

    /// Manifest generation and verification succeed for a valid binary.
    func testManifestGenerationAndVerification() throws {
        let service = Service(name: "Echo", binaryPath: "/bin/echo")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("manifest.json")
        try ManifestGenerator.generate(services: [service], url: url)
        let supervisor = Supervisor()
        XCTAssertNoThrow(try supervisor.verify(services: [service], manifestURL: url))
    }

    /// Verification fails if the manifest is tampered with.
    func testManifestVerificationFailsOnTamper() throws {
        let service = Service(name: "Echo", binaryPath: "/bin/echo")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("tamper.json")
        try ManifestGenerator.generate(services: [service], url: url)
        var entries = try JSONDecoder().decode([ServiceManifestEntry].self, from: Data(contentsOf: url))
        entries[0] = ServiceManifestEntry(name: entries[0].name, binaryPath: entries[0].binaryPath, sha256: "0", permissions: entries[0].permissions)
        try JSONEncoder().encode(entries).write(to: url)
        let supervisor = Supervisor()
        XCTAssertThrowsError(try supervisor.verify(services: [service], manifestURL: url))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
