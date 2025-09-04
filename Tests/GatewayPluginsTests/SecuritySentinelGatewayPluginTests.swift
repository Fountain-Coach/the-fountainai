import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import FountainRuntime
@testable import SecuritySentinelGatewayPlugin

final class SecuritySentinelGatewayPluginTests: XCTestCase {
    func testConsultRequestValidate() throws {
        let valid = ConsultRequest(summary: String(repeating: "a", count: 1000), context: "c")
        XCTAssertNoThrow(try valid.validate())

        let empty = ConsultRequest(summary: "   ", context: "c")
        XCTAssertThrowsError(try empty.validate())

        let long = ConsultRequest(summary: String(repeating: "b", count: 1001), context: "c")
        XCTAssertThrowsError(try long.validate())
    }

    func testRouterRoute() async throws {
        actor MockClient: SecuritySentinelClient {
            private(set) var called = false
            func consult(summary: String, context: [String : (any Codable & Sendable)]?) async throws -> SentinelDecision {
                called = true
                return SentinelDecision(
                    decision: .allow,
                    reason: "ok",
                    confidence: nil,
                    model: nil,
                    requestID: "id",
                    latencyMS: 0,
                    source: .llm,
                    timestamp: "now"
                )
            }

            func reset() { called = false }
            func wasCalled() -> Bool { called }
        }

        let mock = MockClient()
        let original = SentinelClientFactory.make
        SentinelClientFactory.make = { mock }
        defer { SentinelClientFactory.make = original }

        let router = Router()

        let validBody = ConsultRequest(summary: "hi", context: "ctx")
        let validRequest = HTTPRequest(method: "POST", path: "/sentinel/consult", body: try JSONEncoder().encode(validBody))
        let validResponse = try await router.route(validRequest)
        XCTAssertEqual(validResponse?.status, 200)
        var called = await mock.wasCalled()
        XCTAssertTrue(called)

        await mock.reset()
        let invalidSummary = ConsultRequest(summary: "", context: "c")
        let badRequest = HTTPRequest(method: "POST", path: "/sentinel/consult", body: try JSONEncoder().encode(invalidSummary))
        let badResponse = try await router.route(badRequest)
        XCTAssertEqual(badResponse?.status, 400)
        called = await mock.wasCalled()
        XCTAssertFalse(called)

        let malformed = HTTPRequest(method: "POST", path: "/sentinel/consult", body: Data("{".utf8))
        let malformedResponse = try await router.route(malformed)
        XCTAssertEqual(malformedResponse?.status, 400)
    }

    func testAuditLoggerRedact() {
        let ctx = [
            "token": "abc",
            "apikey": "123",
            "mySecret": "foo",
            "user": "bob"
        ]
        let redacted = AuditLogger.redact(ctx)
        XCTAssertEqual(redacted["token"], "[REDACTED]")
        XCTAssertEqual(redacted["apikey"], "[REDACTED]")
        XCTAssertEqual(redacted["mySecret"], "[REDACTED]")
        XCTAssertEqual(redacted["user"], "bob")
    }

    func testAuditLoggerLogConsult() {
        let decision = SentinelDecision(
            decision: .allow,
            reason: "ok",
            confidence: 0.5,
            model: "m",
            requestID: "id",
            latencyMS: 1,
            source: .llm,
            timestamp: "now"
        )
        AuditLogger.logConsult(inputSummary: "hello", context: ["token": "abc"], decision: decision)
    }

    func testHashingSha256Hex() {
        XCTAssertEqual(Hashing.sha256Hex("hello"), "000000310f923099")
        XCTAssertEqual(Hashing.sha256Hex("hello"), Hashing.sha256Hex("hello"))
    }

    func testCircuitBreakerTransitions() async throws {
        let breaker = CircuitBreaker(failureThreshold: 2, openInterval: 0.1)
        var allowed = await breaker.allow()
        XCTAssertTrue(allowed)
        await breaker.recordFailure()
        allowed = await breaker.allow()
        XCTAssertTrue(allowed)
        await breaker.recordFailure()
        allowed = await breaker.allow()
        XCTAssertFalse(allowed)
        try await Task.sleep(nanoseconds: 200_000_000)
        allowed = await breaker.allow()
        XCTAssertTrue(allowed)
    }

    func testRouterUnknownRoute() async throws {
        let router = Router()
        let req = HTTPRequest(method: "GET", path: "/other")
        let resp = try await router.route(req)
        XCTAssertNil(resp)
    }

    func testGatewayPluginInit() async throws {
        let plugin = SecuritySentinelGatewayPlugin()
        let req = HTTPRequest(method: "GET", path: "/none")
        let resp = try await plugin.router.route(req)
        XCTAssertNil(resp)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
