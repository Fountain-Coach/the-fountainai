import Foundation
import Crypto

/// Describes the expected state of an installed service binary.
struct ServiceManifestEntry: Codable, Sendable {
    /// Human readable service name.
    let name: String
    /// Absolute path to the binary on disk.
    let binaryPath: String
    /// SHA-256 hash of the binary contents in lowercase hex.
    let sha256: String
    /// POSIX permission bits expected for the binary.
    let permissions: UInt16
}

enum ManifestError: Error, CustomStringConvertible {
    case missingEntry(String)
    case hashMismatch(String)
    case permissionMismatch(String)

    var description: String {
        switch self {
        case .missingEntry(let path):
            return "manifest missing entry for \(path)"
        case .hashMismatch(let service):
            return "hash mismatch for service \(service)"
        case .permissionMismatch(let service):
            return "permission mismatch for service \(service)"
        }
    }
}

struct ManifestGenerator {
    /// Generates a manifest describing the given services and writes it to disk.
    /// - Parameters:
    ///   - services: Services to include in the manifest.
    ///   - url: Output file location.
    static func generate(services: [Service], url: URL) throws {
        let fm = FileManager.default
        var entries: [ServiceManifestEntry] = []
        for service in services {
            let data = try Data(contentsOf: URL(fileURLWithPath: service.binaryPath))
            let digest = SHA256.hash(data: data)
            let hash = digest.compactMap { String(format: "%02x", $0) }.joined()
            let attrs = try fm.attributesOfItem(atPath: service.binaryPath)
            let perms = (attrs[.posixPermissions] as? NSNumber)?.uint16Value ?? 0
            entries.append(ServiceManifestEntry(name: service.name, binaryPath: service.binaryPath, sha256: hash, permissions: perms))
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(entries)
        try data.write(to: url)
    }
}

extension Supervisor {
    /// Verifies the given services against the provided manifest file.
    /// - Parameters:
    ///   - services: Services to verify.
    ///   - url: Location of the manifest file.
    public func verify(services: [Service], manifestURL url: URL) throws {
        let data = try Data(contentsOf: url)
        let entries = try JSONDecoder().decode([ServiceManifestEntry].self, from: data)
        let table = Dictionary(uniqueKeysWithValues: entries.map { ($0.binaryPath, $0) })
        let fm = FileManager.default
        for service in services {
            guard let entry = table[service.binaryPath] else {
                throw ManifestError.missingEntry(service.binaryPath)
            }
            let fileData = try Data(contentsOf: URL(fileURLWithPath: service.binaryPath))
            let digest = SHA256.hash(data: fileData)
            let hash = digest.compactMap { String(format: "%02x", $0) }.joined()
            if hash != entry.sha256 {
                throw ManifestError.hashMismatch(service.name)
            }
            let attrs = try fm.attributesOfItem(atPath: service.binaryPath)
            let perms = (attrs[.posixPermissions] as? NSNumber)?.uint16Value ?? 0
            if perms != entry.permissions {
                throw ManifestError.permissionMismatch(service.name)
            }
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
