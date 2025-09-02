import Foundation

/// Factory that provides the Security Sentinel client.
public enum SentinelClientFactory {
    /// Create a client capable of consulting the Security Sentinel service.
    public static func make() -> SecuritySentinelClient {
        LLMSecuritySentinelClient()
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
