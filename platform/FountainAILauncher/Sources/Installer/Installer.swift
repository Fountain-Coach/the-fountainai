import Foundation

enum InstallerError: Error, CustomStringConvertible {
    case missingProduct(String)
    case copyFailed(String)

    var description: String {
        switch self {
        case .missingProduct(let product):
            return "built product not found for: \(product)"
        case .copyFailed(let product):
            return "failed to install product: \(product)"
        }
    }
}

struct Installer {
    static func install(services: [Service], repositoryRoot: URL) throws {
        let fm = FileManager.default
        let uniqueServices = ServiceDeduplicator.uniquedByBinaryPath(services).unique
        for service in uniqueServices {
            let product = service.productName
            guard let sourceURL = resolveBuiltProductURL(product: product, repositoryRoot: repositoryRoot) else {
                throw InstallerError.missingProduct(product)
            }
            let destination = service.binaryPath
            let destDir = (destination as NSString).deletingLastPathComponent
            try fm.createDirectory(atPath: destDir, withIntermediateDirectories: true, attributes: nil)
            print("  • installing \(product) → \(destination)")
            do {
                if fm.fileExists(atPath: destination) {
                    try fm.removeItem(atPath: destination)
                }
                try fm.copyItem(atPath: sourceURL.path, toPath: destination)
                print("    ✓ \(product) installed")
            } catch {
                throw InstallerError.copyFailed(product)
            }
        }
    }
}

private extension Service {
    var productName: String {
        URL(fileURLWithPath: binaryPath).lastPathComponent
    }
}

private func resolveBuiltProductURL(product: String, repositoryRoot: URL) -> URL? {
    let fm = FileManager.default
    // 1) Try legacy path
    let legacy = repositoryRoot.appendingPathComponent(".build/release/\(product)")
    if fm.fileExists(atPath: legacy.path) { return legacy }
    // 2) Ask SwiftPM for the bin path
    let proc = Process()
    proc.currentDirectoryURL = repositoryRoot
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    proc.arguments = ["swift", "build", "--show-bin-path", "--configuration", "release"]
    let pipe = Pipe()
    proc.standardOutput = pipe
    proc.standardError = Pipe()
    do { try proc.run() } catch { return nil }
    proc.waitUntilExit()
    guard proc.terminationStatus == 0 else { return nil }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty else { return nil }
    let candidate = URL(fileURLWithPath: path, isDirectory: true).appendingPathComponent(product)
    return fm.fileExists(atPath: candidate.path) ? candidate : nil
}
