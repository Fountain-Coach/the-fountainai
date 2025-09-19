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
    static func install(services: [Service]) throws {
        let fm = FileManager.default
        let uniqueServices = ServiceDeduplicator.uniquedByBinaryPath(services).unique
        for service in uniqueServices {
            let product = service.productName
            let sourcePath = ".build/release/\(product)"
            guard fm.fileExists(atPath: sourcePath) else {
                throw InstallerError.missingProduct(product)
            }
            let destination = service.binaryPath
            let destDir = (destination as NSString).deletingLastPathComponent
            try fm.createDirectory(atPath: destDir, withIntermediateDirectories: true)
            print("  • installing \(product) → \(destination)")
            do {
                if fm.fileExists(atPath: destination) {
                    try fm.removeItem(atPath: destination)
                }
                try fm.copyItem(atPath: sourcePath, toPath: destination)
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
