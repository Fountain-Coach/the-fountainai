import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import FountainAiLauncher
#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif

final class FountainAiLauncherTests: XCTestCase {
    func testServiceLaunch() throws {
        let supervisor = Supervisor(launcherSignature: "test")
        let service = Service(name: "Echo", binaryPath: "/usr/bin/env", arguments: ["true"])
        let process = try supervisor.start(service: service)
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
    }

    func testTerminateAllStopsProcesses() throws {
        let supervisor = Supervisor(launcherSignature: "test")
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
        let supervisor = Supervisor(launcherSignature: "test")
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
        let supervisor = Supervisor(launcherSignature: "test")
        XCTAssertThrowsError(try supervisor.verify(services: [service], manifestURL: url))
    }

    /// Control plane status endpoint lists running services.
    func testControlPlaneStatus() async throws {
        let supervisor = Supervisor(launcherSignature: "test")
        let service = Service(name: "Sleep", binaryPath: "/bin/sleep", arguments: ["10"])
        _ = try supervisor.start(service: service)
        let cp = ControlPlane(supervisor: supervisor, services: [service])
        let port = try await cp.start(port: 0)
        defer {
            supervisor.terminateAll()
            Task { try? await cp.stop() }
        }
        let url = URL(string: "http://127.0.0.1:\(port)/status")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let statuses = try JSONDecoder().decode([ServiceStatus].self, from: data)
        XCTAssertEqual(statuses.first?.name, service.name)
        XCTAssertEqual(statuses.first?.running, true)
    }

    /// Restart endpoint returns 200 for known service.
    func testControlPlaneRestart() async throws {
        let supervisor = Supervisor(launcherSignature: "test")
        let service = Service(name: "Sleep", binaryPath: "/bin/sleep", arguments: ["10"])
        _ = try supervisor.start(service: service)
        let cp = ControlPlane(supervisor: supervisor, services: [service])
        let port = try await cp.start(port: 0)
        defer {
            supervisor.terminateAll()
            Task { try? await cp.stop() }
        }
        var request = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/restart/\(service.name)")!)
        request.httpMethod = "POST"
        let (_, response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
    }

    /// Restart endpoint returns 404 for unknown service.
    func testControlPlaneRestartUnknownService() async throws {
        let supervisor = Supervisor(launcherSignature: "test")
        let service = Service(name: "Sleep", binaryPath: "/bin/sleep", arguments: ["10"])
        _ = try supervisor.start(service: service)
        let cp = ControlPlane(supervisor: supervisor, services: [service])
        let port = try await cp.start(port: 0)
        defer {
            supervisor.terminateAll()
            Task { try? await cp.stop() }
        }
        var request = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/restart/UnknownService")!)
        request.httpMethod = "POST"
        let (_, response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 404)
    }

    /// Shutdown endpoint returns 200.
    func testControlPlaneShutdown() async throws {
        let supervisor = Supervisor(launcherSignature: "test")
        let cp = ControlPlane(supervisor: supervisor, services: [])
        _ = try await cp.start(port: 0)
        try await cp.stop()
    }

    func testServiceDeduplicationByBinaryPath() {
        let binary = "/bin/echo"
        let serviceA = Service(name: "Gateway Auth", binaryPath: binary)
        let serviceB = Service(name: "Gateway Rate Limiter", binaryPath: binary)
        let result = ServiceDeduplicator.uniquedByBinaryPath([serviceA, serviceB])
        XCTAssertEqual(result.unique.count, 1)
        XCTAssertEqual(result.unique.first?.name, serviceA.name)
        XCTAssertEqual(result.duplicates[binary]?.count, 1)
        XCTAssertEqual(result.duplicates[binary]?.first?.name, serviceB.name)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
