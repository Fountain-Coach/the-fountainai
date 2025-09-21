import XCTest
import Yams

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
}

struct ServiceDescriptor {
    let fileName: String
    let title: String
    let port: Int
    let healthPaths: [String]
    let capabilityPaths: [String]
}

struct ServiceDiscovery {
    let openAPIRoot: URL

    func loadServices() throws -> [ServiceDescriptor] {
        let manager = FileManager.default
        let files = try manager.contentsOfDirectory(at: openAPIRoot, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension.lowercased() == "yml" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        return try files.compactMap { url in
            let yamlString = try String(contentsOf: url, encoding: .utf8)
            guard let root = try Yams.load(yaml: yamlString) as? [String: Any] else { return nil }

            let info = root["info"] as? [String: Any] ?? [:]
            let title = (info["title"] as? String) ?? url.deletingPathExtension().lastPathComponent
            guard let port = ServiceDiscovery.parsePort(info["x-fountain.port"]) else { return nil }
            let paths = root["paths"] as? [String: Any] ?? [:]

            let health = ServiceDiscovery.extractPaths(paths, containing: "health")
            let capabilities = ServiceDiscovery.extractPaths(paths, containing: "capabilities")

            return ServiceDescriptor(
                fileName: url.lastPathComponent,
                title: title,
                port: port,
                healthPaths: health,
                capabilityPaths: capabilities
            )
        }
    }

    private static func parsePort(_ value: Any?) -> Int? {
        switch value {
        case let intValue as Int:
            return intValue
        case let stringValue as String:
            return Int(stringValue)
        case let doubleValue as Double:
            return Int(doubleValue)
        default:
            return nil
        }
    }

    private static func extractPaths(_ paths: [String: Any], containing substring: String) -> [String] {
        let lowercased = substring.lowercased()
        return paths.keys
            .filter { $0.lowercased().contains(lowercased) }
            .sorted()
    }
}
