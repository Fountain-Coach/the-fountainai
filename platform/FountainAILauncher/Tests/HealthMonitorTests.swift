import XCTest
import Foundation
@testable import FountainAiLauncher

final class HealthMonitorTests: XCTestCase {
    final class MockSupervisor: SupervisorProtocol, @unchecked Sendable {
        var restarted: [String] = []
        var onRestart: ((Service) -> Void)?
        func restart(service: Service) {
            restarted.append(service.name)
            onRestart?(service)
        }
    }

    func testStartMonitoringTriggersRestartOnFailure() {
        let mock = MockSupervisor()
        let exp = expectation(description: "restart")
        mock.onRestart = { _ in exp.fulfill() }
        var monitor: HealthMonitor? = HealthMonitor(supervisor: mock, interval: 0.1)
        let failing = Service(name: "Failing", binaryPath: "/bin/echo", port: 65535, healthPath: "/health", shouldRestart: true)
        monitor?.startMonitoring(services: [failing])
        wait(for: [exp], timeout: 1.0)
        monitor = nil
    }

    func testServicesWithoutPortOrPathAreIgnored() {
        let mock = MockSupervisor()
        let exp = expectation(description: "no restart")
        exp.isInverted = true
        mock.onRestart = { _ in exp.fulfill() }
        var monitor: HealthMonitor? = HealthMonitor(supervisor: mock, interval: 0.1)
        let noPort = Service(name: "NoPort", binaryPath: "/bin/echo", healthPath: "/health", shouldRestart: true)
        let noPath = Service(name: "NoPath", binaryPath: "/bin/echo", port: 65535, shouldRestart: true)
        monitor?.startMonitoring(services: [noPort, noPath])
        wait(for: [exp], timeout: 0.5)
        XCTAssertTrue(mock.restarted.isEmpty)
        monitor = nil
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
