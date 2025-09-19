import Foundation
import Yams

/// Loads service definitions from OpenAPI specifications.
/// Scans `openapi/v*/` for YAML files that declare `x-fountain.binary`
/// and converts them into ``Service`` descriptors for the launcher.
enum OpenAPIServiceLoader {
    /// Returns all services described by OpenAPI gateway specs.
    /// - Parameter root: Root directory containing the `openapi` folder.
    static func loadServices(root: URL, servicesDirectory: URL) throws -> [Service] {
        let fm = FileManager.default
        let openapiURL = root
        let servicesDir = servicesDirectory.path
        var result: [Service] = []
        guard fm.fileExists(atPath: openapiURL.path) else { return result }
        let versionDirs = try fm.contentsOfDirectory(at: openapiURL, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("v") }
        for version in versionDirs {
            let specs = try fm.contentsOfDirectory(at: version, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension.lowercased() == "yml" || $0.pathExtension.lowercased() == "yaml" }
            for spec in specs {
                do {
                    let contents = try String(contentsOf: spec, encoding: .utf8)
                    guard let yaml = try Yams.load(yaml: contents) as? [String: Any] else { continue }
                    let info = yaml["info"] as? [String: Any]
                    let extensions = yaml["x-fountain"] as? [String: Any]
                    let title = info?["title"] as? String ?? spec.deletingPathExtension().lastPathComponent
                    let binaryName = (info?["x-fountain.binary"] as? String)
                        ?? (extensions?["binary"] as? String)
                        ?? (yaml["x-fountain.binary"] as? String)
                    guard let resolvedBinary = binaryName else { continue }
                    var port = (info?["x-fountain.port"] as? Int)
                        ?? (extensions?["port"] as? Int)
                        ?? (yaml["x-fountain.port"] as? Int)
                    if port == nil,
                       let servers = yaml["servers"] as? [[String: Any]],
                       let urlString = servers.first? ["url"] as? String,
                       let url = URL(string: urlString),
                       let urlPort = url.port {
                       port = urlPort
                    }
                    let binaryPath = (servicesDir as NSString).appendingPathComponent(resolvedBinary)
                    result.append(Service(
                        name: title,
                        binaryPath: binaryPath,
                        arguments: [],
                        port: port,
                        healthPath: "/metrics",
                        shouldRestart: true
                    ))
                } catch {
                    let message = "Skipping OpenAPI spec at \(spec.path) due to parse error: \(error)"
                    FileHandle.standardError.write(Data((message + "\n").utf8))
                }
            }
        }
        return result
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
