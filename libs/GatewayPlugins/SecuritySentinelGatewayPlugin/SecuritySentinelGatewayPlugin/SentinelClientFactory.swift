import Foundation

/// Factory that provides the Security Sentinel client.
enum SentinelClientFactory {
    static func make() -> SecuritySentinelClient {
        LLMSecuritySentinelClient()
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
