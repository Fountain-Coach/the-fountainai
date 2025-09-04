import Foundation
import Yams

/// Configuration for the gateway server.
public struct GatewayConfig: Codable {
    /// Default per-client limit when routes omit an explicit value.
    public var rateLimitPerMinute: Int

    public init(rateLimitPerMinute: Int = 60) {
        self.rateLimitPerMinute = rateLimitPerMinute
    }
}

/// Loads gateway configuration from `Configuration/gateway.yml`.
/// Lines beginning with a copyright symbol are ignored to keep YAML parseable.
public func loadGatewayConfig() throws -> GatewayConfig {
    let url = URL(fileURLWithPath: "Configuration/gateway.yml")
    let raw = try String(contentsOf: url, encoding: .utf8)
    let sanitized = raw
        .split(separator: "\n", omittingEmptySubsequences: false)
        .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("©") }
        .joined(separator: "\n")
    let yaml = try Yams.load(yaml: sanitized) as? [String: Any] ?? [:]
    let defaults: [String: Any] = ["rateLimitPerMinute": 60]
    let merged = defaults.merging(yaml) { _, new in new }
    let data = try JSONSerialization.data(withJSONObject: merged)
    return try JSONDecoder().decode(GatewayConfig.self, from: data)
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
