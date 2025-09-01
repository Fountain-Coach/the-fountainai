import XCTest
@testable import SecuritySentinelGatewayPlugin

final class SentinelClientFactoryTests: XCTestCase {
    override func tearDown() {
        unsetenv("SEC_SENTINEL_ENABLED")
        unsetenv("SEC_SENTINEL_URL")
        unsetenv("SEC_SENTINEL_API_KEY")
        super.tearDown()
    }

    func testReturnsRuleBasedWhenDisabled() {
        setenv("SEC_SENTINEL_ENABLED", "false", 1)
        let client = SentinelClientFactory.make()
        XCTAssertTrue(client is RuleBasedSecuritySentinelClient)
    }

    func testReturnsRuleBasedWhenMissingConfig() {
        setenv("SEC_SENTINEL_ENABLED", "true", 1)
        unsetenv("SEC_SENTINEL_URL")
        unsetenv("SEC_SENTINEL_API_KEY")
        let client = SentinelClientFactory.make()
        XCTAssertTrue(client is RuleBasedSecuritySentinelClient)
    }

    func testReturnsLLMWhenEnabledAndConfigured() {
        setenv("SEC_SENTINEL_ENABLED", "true", 1)
        setenv("SEC_SENTINEL_URL", "http://localhost", 1)
        setenv("SEC_SENTINEL_API_KEY", "test", 1)
        let client = SentinelClientFactory.make()
        XCTAssertTrue(client is LLMSecuritySentinelClient)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
