import Foundation

struct RepositoryLayout {
    let root: URL
    let openAPIRoot: URL
    let servicesDirectory: URL

    static func detect(fileManager fm: FileManager = .default) throws -> RepositoryLayout {
        if let override = ProcessInfo.processInfo.environment["FOUNTAINAI_ROOT"], !override.isEmpty {
            let rootURL = URL(fileURLWithPath: override, isDirectory: true)
            let openapiURL = rootURL.appendingPathComponent("openapi")
            guard fm.fileExists(atPath: openapiURL.path) else {
                throw LayoutError.openapiNotFound(openapiURL.path)
            }
            let servicesDirPath = ProcessInfo.processInfo.environment["FOUNTAINAI_SERVICES_DIR"] ?? rootURL.appendingPathComponent("dist/bin").path
            let servicesDir = URL(fileURLWithPath: servicesDirPath, isDirectory: true)
            try fm.createDirectory(at: servicesDir, withIntermediateDirectories: true)
            return RepositoryLayout(root: rootURL, openAPIRoot: openapiURL, servicesDirectory: servicesDir)
        }

        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
        guard let root = findRepositoryRoot(startingAt: cwd, fileManager: fm) else {
            throw LayoutError.repositoryRootNotFound
        }
        let openapi = root.appendingPathComponent("openapi")
        guard fm.fileExists(atPath: openapi.path) else {
            throw LayoutError.openapiNotFound(openapi.path)
        }
        let servicesDirPath = ProcessInfo.processInfo.environment["FOUNTAINAI_SERVICES_DIR"] ?? root.appendingPathComponent("dist/bin").path
        let servicesDir = URL(fileURLWithPath: servicesDirPath, isDirectory: true)
        try fm.createDirectory(at: servicesDir, withIntermediateDirectories: true, attributes: nil)
        return RepositoryLayout(root: root, openAPIRoot: openapi, servicesDirectory: servicesDir)
    }

    private static func findRepositoryRoot(startingAt url: URL, fileManager fm: FileManager) -> URL? {
        var current = url
        for _ in 0..<10 {
            if fm.fileExists(atPath: current.appendingPathComponent("Package.swift").path) &&
               fm.fileExists(atPath: current.appendingPathComponent("openapi").path) {
                return current
            }
            let parent = current.deletingLastPathComponent()
            if parent.path == current.path { break }
            current = parent
        }
        return nil
    }

    enum LayoutError: Error, CustomStringConvertible {
        case repositoryRootNotFound
        case openapiNotFound(String)

        var description: String {
            switch self {
            case .repositoryRootNotFound:
                return "Unable to locate repository root; run the launcher from inside the FountainAI repo."
            case let .openapiNotFound(path):
                return "OpenAPI specifications not found at \(path)."
            }
        }
    }
}
