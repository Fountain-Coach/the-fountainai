import XCTest
@testable import TutorDashboard

final class ServiceDiscoveryTests: XCTestCase {
    func testEnumeratesServicesAndFlagsMissingEndpoints() throws {
        let testDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let packageRoot = testDirectory.deletingLastPathComponent().deletingLastPathComponent()
        let openAPIRoot = packageRoot.appendingPathComponent("openapi/v1", isDirectory: true)

        let discovery = ServiceDiscovery(openAPIRoot: openAPIRoot)
        let services = try discovery.loadServices()

        let servicesByFile = Dictionary(uniqueKeysWithValues: services.map { ($0.fileName, $0) })

        let expected: [String: (port: Int, hasHealth: Bool, hasCapabilities: Bool)] = [
            "baseline-awareness.yml": (port: 8001, hasHealth: true, hasCapabilities: false),
            "bootstrap.yml": (port: 8002, hasHealth: false, hasCapabilities: false),
            "persist.yml": (port: 8005, hasHealth: false, hasCapabilities: true),
            "planner.yml": (port: 8003, hasHealth: false, hasCapabilities: false),
            "function-caller.yml": (port: 8004, hasHealth: false, hasCapabilities: false),
            "tools-factory.yml": (port: 8011, hasHealth: false, hasCapabilities: false),
            "semantic-browser.yml": (port: 8007, hasHealth: true, hasCapabilities: false)
        ]

        XCTAssertGreaterThanOrEqual(servicesByFile.count, expected.count, "Expected to discover module 01 services")

        for (fileName, expectation) in expected {
            guard let descriptor = servicesByFile[fileName] else {
                XCTFail("Missing descriptor for \(fileName)")
                continue
            }

            XCTAssertEqual(descriptor.port, expectation.port, "Unexpected port for \(fileName)")
            XCTAssertEqual(!descriptor.healthPaths.isEmpty, expectation.hasHealth, "Health path mismatch for \(fileName)")
            XCTAssertEqual(!descriptor.capabilityPaths.isEmpty, expectation.hasCapabilities, "Capabilities path mismatch for \(fileName)")
        }
    }
    func testResolveBaseURLPrefersEnvironmentAndFallsBack() {
        let descriptor = ServiceDescriptor(
            fileName: "persist.yml",
            title: "FountainStore Persistence Service",
            binaryName: "persist",
            port: 8005,
            servers: [],
            healthPaths: [],
            capabilityPaths: []
        )

        let envURL = "https://store.example.com"
        XCTAssertEqual(
            descriptor.resolveBaseURL(environment: ["FOUNTAINSTORE_URL": envURL])?.absoluteString,
            envURL
        )

        let serverURL = URL(string: "http://persist.local")!
        let serverBacked = ServiceDescriptor(
            fileName: "persist.yml",
            title: "FountainStore Persistence Service",
            binaryName: "persist",
            port: 8005,
            servers: [serverURL],
            healthPaths: [],
            capabilityPaths: []
        )

        XCTAssertEqual(serverBacked.resolveBaseURL(environment: [:]), serverURL)

        let portFallback = ServiceDescriptor(
            fileName: "bootstrap.yml",
            title: "FountainAI Bootstrap Service",
            binaryName: "bootstrap",
            port: 9000,
            servers: [],
            healthPaths: [],
            capabilityPaths: []
        )

        XCTAssertEqual(
            portFallback.resolveBaseURL(environment: [:])?.absoluteString,
            "http://127.0.0.1:9000"
        )
    }
}
