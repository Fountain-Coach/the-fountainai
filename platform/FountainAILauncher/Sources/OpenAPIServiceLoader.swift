import Foundation
import Yams

/// Loads service definitions from OpenAPI gateway specifications.
/// Scans `openapi/v*/` for files ending in `-gateway.yml` and converts
/// them into ``Service`` descriptors for the launcher.
enum OpenAPIServiceLoader {
    /// Returns all services described by OpenAPI gateway specs.
    /// - Parameter root: Root directory containing the `openapi` folder.
    static func loadServices(root: URL = URL(fileURLWithPath: "")) throws -> [Service] {
        let fm = FileManager.default
        let openapiURL = root.appendingPathComponent("openapi")
        let servicesDir = ProcessInfo.processInfo.environment["FOUNTAINAI_SERVICES_DIR"] ?? "/usr/local/bin"
        var result: [Service] = []
        guard fm.fileExists(atPath: openapiURL.path) else { return result }
        let versionDirs = try fm.contentsOfDirectory(at: openapiURL, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("v") }
        for version in versionDirs {
            let specs = try fm.contentsOfDirectory(at: version, includingPropertiesForKeys: nil)
                .filter { $0.lastPathComponent.hasSuffix("-gateway.yml") }
            for spec in specs {
                let contents = try String(contentsOf: spec, encoding: .utf8)
                guard let yaml = try Yams.load(yaml: contents) as? [String: Any] else { continue }
                let info = yaml["info"] as? [String: Any]
                let title = info?["title"] as? String ?? spec.deletingPathExtension().lastPathComponent
                let binaryName = yaml["x-fountain.binary"] as? String ?? spec.deletingPathExtension().lastPathComponent
                var port = yaml["x-fountain.port"] as? Int
                if port == nil,
                   let servers = yaml["servers"] as? [[String: Any]],
                   let urlString = servers.first? ["url"] as? String,
                   let url = URL(string: urlString),
                   let urlPort = url.port {
                    port = urlPort
                }
                let binaryPath = (servicesDir as NSString).appendingPathComponent(binaryName)
                result.append(Service(
                    name: title,
                    binaryPath: binaryPath,
                    arguments: [],
                    port: port,
                    healthPath: "/metrics",
                    shouldRestart: true
                ))
            }
        }
        return result
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
