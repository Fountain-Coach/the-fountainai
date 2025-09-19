import Foundation

/// Persists and retrieves the launcher signature used to validate
/// precompiled service binaries at runtime.
struct SignatureStore {
    /// File name stored alongside `dist/bin` at `dist/.launcher_signature`.
    private static let fileName = ".launcher_signature"

    /// Returns the URL of the signature file inside the `dist` directory.
    /// - Parameter layout: Repository layout with `servicesDirectory` at `dist/bin`.
    static func url(for layout: RepositoryLayout) -> URL {
        let distRoot = layout.servicesDirectory.deletingLastPathComponent()
        return distRoot.appendingPathComponent(fileName)
    }

    /// Loads a previously persisted signature if present.
    /// - Parameter layout: Repository layout.
    /// - Returns: The signature string or `nil` if not found/readable.
    static func load(from layout: RepositoryLayout) -> String? {
        let url = url(for: layout)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Persists the given signature for later reuse.
    /// - Parameters:
    ///   - signature: Signature value to persist.
    ///   - layout: Repository layout.
    static func save(_ signature: String, layout: RepositoryLayout) throws {
        let url = url(for: layout)
        let distRoot = layout.servicesDirectory.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: distRoot, withIntermediateDirectories: true)
        try (signature + "\n").write(to: url, atomically: true, encoding: .utf8)
    }
}

