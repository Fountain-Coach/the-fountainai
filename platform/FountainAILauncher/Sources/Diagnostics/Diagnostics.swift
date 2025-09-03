import Foundation

enum DiagnosticsError: Error, CustomStringConvertible {
    case cannotReadEnv
    case missingEnv(String)

    var description: String {
        switch self {
        case .cannotReadEnv:
            return "Unable to read .env file"
        case .missingEnv(let key):
            return "Missing required environment variable: \(key)"
        }
    }
}

struct Diagnostics {
    static let requiredKeys = ["OPENAI_API_KEY", "FOUNTAINSTORE_URL", "FOUNTAINSTORE_API_KEY"]

    static func loadEnv() throws {
        let url = URL(fileURLWithPath: ".env")
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else {
            throw DiagnosticsError.cannotReadEnv
        }
        for line in content.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                setenv(String(parts[0]), String(parts[1]), 1)
            }
        }
    }

    static func validateEnv() throws {
        for key in requiredKeys {
            let value = ProcessInfo.processInfo.environment[key] ?? ""
            if value.isEmpty {
                throw DiagnosticsError.missingEnv(key)
            }
        }
    }

    static func run() throws {
        try loadEnv()
        try validateEnv()
    }
}
