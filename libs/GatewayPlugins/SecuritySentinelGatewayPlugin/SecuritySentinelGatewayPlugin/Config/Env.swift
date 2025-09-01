import Foundation

/// Environment configuration for the LLM Security Sentinel client.
enum SentinelEnv {
    static let enabled = (ProcessInfo.processInfo.environment["SEC_SENTINEL_ENABLED"] ?? "true").lowercased() != "false"
    static let url = ProcessInfo.processInfo.environment["SEC_SENTINEL_URL"]
    static let apiKey = ProcessInfo.processInfo.environment["SEC_SENTINEL_API_KEY"]
    static let timeoutMS = Int(ProcessInfo.processInfo.environment["SEC_SENTINEL_TIMEOUT_MS"] ?? "4000") ?? 4000
    static let retries = Int(ProcessInfo.processInfo.environment["SEC_SENTINEL_RETRIES"] ?? "1") ?? 1
    static let model = ProcessInfo.processInfo.environment["SEC_SENTINEL_MODEL"]
    static let failMode = ProcessInfo.processInfo.environment["SEC_SENTINEL_FAIL_MODE"] ?? "fallback" // allow|deny|fallback
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
