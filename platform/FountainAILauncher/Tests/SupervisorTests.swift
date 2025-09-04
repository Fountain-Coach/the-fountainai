import XCTest
import Foundation
@testable import FountainAiLauncher
#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif

final class SupervisorTests: XCTestCase {
    func testStartRegistersProcess() throws {
        let supervisor = Supervisor(launcherSignature: "test")
        let service = Service(name: "Sleep", binaryPath: "/bin/sleep", arguments: ["5"])
        let process = try supervisor.start(service: service)
        defer { supervisor.terminateAll() }
        XCTAssertTrue(process.isRunning)
        XCTAssertTrue(supervisor.isRunning(serviceName: service.name))
    }

    func testRestartReplacesProcess() throws {
        let supervisor = Supervisor(launcherSignature: "test")
        let service = Service(name: "Sleep", binaryPath: "/bin/sleep", arguments: ["5"])
        let process = try supervisor.start(service: service)
        XCTAssertTrue(process.isRunning)
        supervisor.restart(service: service)
        sleep(1)
        XCTAssertFalse(process.isRunning)
        XCTAssertTrue(supervisor.isRunning(serviceName: service.name))
        supervisor.terminateAll()
    }

    func testTerminateAllClearsProcesses() throws {
        let supervisor = Supervisor(launcherSignature: "test")
        let service1 = Service(name: "Sleep1", binaryPath: "/bin/sleep", arguments: ["5"])
        let service2 = Service(name: "Sleep2", binaryPath: "/bin/sleep", arguments: ["5"])
        _ = try supervisor.start(service: service1)
        _ = try supervisor.start(service: service2)
        XCTAssertTrue(supervisor.isRunning(serviceName: service1.name))
        XCTAssertTrue(supervisor.isRunning(serviceName: service2.name))
        supervisor.terminateAll()
        sleep(1)
        XCTAssertFalse(supervisor.isRunning(serviceName: service1.name))
        XCTAssertFalse(supervisor.isRunning(serviceName: service2.name))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
