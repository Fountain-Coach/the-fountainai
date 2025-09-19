import Foundation

enum BuilderError: Error, CustomStringConvertible {
    case buildFailed(String)

    var description: String {
        switch self {
        case .buildFailed(let product):
            return "swift build failed for product: \(product)"
        }
    }
}

struct Builder {
    static func build(services: [Service], signature: String) throws {
        // Embed launcher signature into shared library so each service
        // binary includes a compile-time token.
        let sigURL = URL(fileURLWithPath: "libs/LauncherSignature/Signature.swift")
        let sigContent = "public let embeddedLauncherSignature = \"\(signature)\"\n"
        try sigContent.write(to: sigURL, atomically: true, encoding: .utf8)

        let uniqueServices = ServiceDeduplicator.uniquedByBinaryPath(services).unique
        for service in uniqueServices {
            let product = service.productName
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["swift", "build", "--configuration", "release", "--product", product]
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                throw BuilderError.buildFailed(product)
            }
        }
    }
}

private extension Service {
    var productName: String {
        URL(fileURLWithPath: binaryPath).lastPathComponent
    }
}
