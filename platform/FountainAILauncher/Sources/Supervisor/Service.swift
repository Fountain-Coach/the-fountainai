import Foundation

/// Describes an executable service managed by ``Supervisor``.
public struct Service: Codable, Sendable {
    /// Human readable identifier used by ``Supervisor``.
    public let name: String
    /// Absolute path to the executable binary on disk.
    public let binaryPath: String
    /// Arguments passed to the process on launch.
    public let arguments: [String]
    /// Optional port used for health checks.
    public let port: Int?
    /// Optional HTTP path of the health check endpoint.
    public let healthPath: String?
    /// Whether the supervisor should attempt to restart the service if a
    /// health check fails.
    public let shouldRestart: Bool

    /// Creates a new service descriptor.
    /// - Parameters:
    ///   - name: Human readable identifier.
    ///   - binaryPath: Absolute path to the executable.
    ///   - arguments: Arguments passed on launch.
    ///   - port: Optional port for health checks.
    ///   - healthPath: Health check endpoint path.
    ///   - shouldRestart: Restart automatically on failed health checks.
    public init(
        name: String,
        binaryPath: String,
        arguments: [String] = [],
        port: Int? = nil,
        healthPath: String? = nil,
        shouldRestart: Bool = false
    ) {
        self.name = name
        self.binaryPath = binaryPath
        self.arguments = arguments
        self.port = port
        self.healthPath = healthPath
        self.shouldRestart = shouldRestart
    }

    private enum CodingKeys: String, CodingKey {
        case name, binaryPath, arguments, port, healthPath, shouldRestart
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        binaryPath = try container.decode(String.self, forKey: .binaryPath)
        arguments = try container.decodeIfPresent([String].self, forKey: .arguments) ?? []
        port = try container.decodeIfPresent(Int.self, forKey: .port)
        healthPath = try container.decodeIfPresent(String.self, forKey: .healthPath)
        shouldRestart = try container.decodeIfPresent(Bool.self, forKey: .shouldRestart) ?? false
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
