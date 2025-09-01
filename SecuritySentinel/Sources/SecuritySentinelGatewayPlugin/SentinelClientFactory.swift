import Foundation

/// Factory that selects the appropriate Security Sentinel client based on environment.
enum SentinelClientFactory {
    static func make() -> SecuritySentinelClient {
        guard SentinelEnv.enabled,
              SentinelEnv.url != nil,
              SentinelEnv.apiKey != nil else {
            return RuleBasedSecuritySentinelClient()
        }
        return LLMSecuritySentinelClient()
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
