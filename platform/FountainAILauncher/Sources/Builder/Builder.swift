import Foundation

enum BuilderError: Error, CustomStringConvertible {
    case buildFailed(String)
    case missingSignatureFile

    var description: String {
        switch self {
        case .buildFailed(let product):
            return "swift build failed for product: \(product)"
        case .missingSignatureFile:
            return "Could not locate libs/LauncherSignature/Signature.swift"
        }
    }
}

struct Builder {
    static func build(services: [Service], signature: String) throws {
        // Embed launcher signature into shared library so each service
        // binary includes a compile-time token.
        let sigURL = try locateSignatureFile()
        let sigContent = "public let embeddedLauncherSignature = \"\(signature)\"\n"
        try sigContent.write(to: sigURL, atomically: true, encoding: .utf8)

        let uniqueServices = ServiceDeduplicator.uniquedByBinaryPath(services).unique
        for service in uniqueServices {
            let product = service.productName
            let process = Process()
            let (executable, arguments) = buildInvocation(for: product)
            process.executableURL = executable
            process.arguments = arguments
            print("  • building \(product)…")

            process.standardOutput = FileHandle.standardOutput
            process.standardError = FileHandle.standardError

            try process.run()
            let heartbeat = Heartbeat(message: "    … still building \(product)")
            heartbeat.start()
            defer { heartbeat.stop() }
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                throw BuilderError.buildFailed(product)
            }
            print("    ✓ \(product) built")
        }
    }
}

private extension Service {
    var productName: String {
        URL(fileURLWithPath: binaryPath).lastPathComponent
    }
}

private extension Builder {
    static func locateSignatureFile(fileManager fm: FileManager = .default) throws -> URL {
        var directory = URL(fileURLWithPath: fm.currentDirectoryPath)
        for _ in 0..<6 {
            let candidate = directory.appendingPathComponent("libs/LauncherSignature/Signature.swift")
            if fm.fileExists(atPath: candidate.path) {
                return candidate
            }
            if directory.pathComponents.count <= 1 { break }
            directory.deleteLastPathComponent()
        }
        throw BuilderError.missingSignatureFile
    }

    static func buildInvocation(for product: String) -> (URL, [String]) {
        let scriptPath = "/usr/bin/script"
        if FileManager.default.isExecutableFile(atPath: scriptPath) {
            let exe = URL(fileURLWithPath: scriptPath)
            let args = ["-q", "/dev/null", "swift", "build", "--configuration", "release", "--product", product]
            return (exe, args)
        }
        let exe = URL(fileURLWithPath: "/usr/bin/env")
        let args = ["swift", "build", "--configuration", "release", "--product", product]
        return (exe, args)
    }
}
