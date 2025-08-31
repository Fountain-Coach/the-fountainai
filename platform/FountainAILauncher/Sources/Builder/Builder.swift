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
    static func build(services: [Service]) throws {
        for service in services {
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
