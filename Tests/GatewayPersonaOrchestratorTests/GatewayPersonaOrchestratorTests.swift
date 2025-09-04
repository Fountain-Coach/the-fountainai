import XCTest
@testable import GatewayPersonaOrchestrator
import FountainRuntime
import SecuritySentinelGatewayPlugin
import DestructiveGuardianGatewayPlugin

final class GatewayPersonaOrchestratorTests: XCTestCase {
    struct StubPersona: GatewayPersona {
        let name: String
        let verdict: GatewayPersonaVerdict
        func evaluate(_ request: HTTPRequest) async -> GatewayPersonaVerdict { verdict }
    }

    struct StubSentinelClient: SecuritySentinelClient {
        let action: @Sendable () throws -> SentinelDecision
        func consult(summary: String, context: [String : (any Codable & Sendable)]?) async throws -> SentinelDecision {
            try action()
        }
    }

    struct StubGuardianHandler: GuardianEvaluating {
        let action: @Sendable (HTTPRequest, GuardianEvaluateRequest?) throws -> HTTPResponse
        func guardianEvaluate(_ request: HTTPRequest, body: GuardianEvaluateRequest?) async throws -> HTTPResponse {
            try action(request, body)
        }
    }

    func testDenyShortCircuitsToDeny() async {
        let personas: [GatewayPersona] = [
            StubPersona(name: "allow", verdict: .allow),
            StubPersona(name: "deny", verdict: .deny(reason: "nope", persona: "deny")),
            StubPersona(name: "escalate", verdict: .escalate(reason: "maybe", persona: "escalate"))
        ]
        let orchestrator = GatewayPersonaOrchestrator(personas: personas)
        let result = await orchestrator.decide(for: HTTPRequest(method: "GET", path: "/"))
        if case .deny(_, let p) = result {
            XCTAssertEqual(p, "deny")
        } else {
            XCTFail("expected deny")
        }
    }

    func testMixedAllowAndEscalateYieldsEscalate() async {
        let personas: [GatewayPersona] = [
            StubPersona(name: "esc", verdict: .escalate(reason: "maybe", persona: "esc")),
            StubPersona(name: "allow", verdict: .allow)
        ]
        let orchestrator = GatewayPersonaOrchestrator(personas: personas)
        let result = await orchestrator.decide(for: HTTPRequest(method: "GET", path: "/"))
        if case .escalate(_, let p) = result {
            XCTAssertEqual(p, "esc")
        } else {
            XCTFail("expected escalate")
        }
    }

    func testAllAllowReturnsAllow() async {
        let personas: [GatewayPersona] = [
            StubPersona(name: "one", verdict: .allow),
            StubPersona(name: "two", verdict: .allow)
        ]
        let orchestrator = GatewayPersonaOrchestrator(personas: personas)
        let result = await orchestrator.decide(for: HTTPRequest(method: "GET", path: "/"))
        if case .allow = result {
            // success
        } else {
            XCTFail("expected allow")
        }
    }

    func testSecuritySentinelPersonaBranches() async {
        let request = HTTPRequest(method: "GET", path: "/")
        let makeDecision: @Sendable (SentinelVerdict) -> SentinelDecision = { verdict in
            SentinelDecision(decision: verdict,
                             reason: "r",
                             confidence: nil,
                             model: nil,
                             requestID: "id",
                             latencyMS: 0,
                             source: .llm,
                             timestamp: "t")
        }
        var persona = SecuritySentinelPersona(client: StubSentinelClient { makeDecision(.allow) })
        var res = await persona.evaluate(request)
        if case .allow = res {} else { XCTFail("expected allow") }

        persona = SecuritySentinelPersona(client: StubSentinelClient { makeDecision(.deny) })
        res = await persona.evaluate(request)
        if case .deny(_, let name) = res {
            XCTAssertEqual(name, "SecuritySentinel")
        } else { XCTFail("expected deny") }

        persona = SecuritySentinelPersona(client: StubSentinelClient { makeDecision(.escalate) })
        res = await persona.evaluate(request)
        if case .escalate(_, let name) = res {
            XCTAssertEqual(name, "SecuritySentinel")
        } else { XCTFail("expected escalate") }

        struct TestError: Error {}
        persona = SecuritySentinelPersona(client: StubSentinelClient { throw TestError() })
        res = await persona.evaluate(request)
        if case .escalate(let reason, let name) = res {
            XCTAssertEqual(name, "SecuritySentinel")
            XCTAssertTrue(reason.contains("error"))
        } else { XCTFail("expected escalate on error") }
    }

    func testDestructiveGuardianPersonaBranches() async {
        let request = HTTPRequest(method: "DELETE", path: "/danger")
        let makeResponse: @Sendable (String) -> HTTPResponse = { decision in
            let data = try! JSONEncoder().encode(["decision": decision])
            return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
        }

        var persona = DestructiveGuardianPersona(handler: StubGuardianHandler { _, _ in makeResponse("allow") })
        var res = await persona.evaluate(request)
        if case .allow = res {} else { XCTFail("expected allow") }

        persona = DestructiveGuardianPersona(handler: StubGuardianHandler { _, _ in makeResponse("deny") })
        res = await persona.evaluate(request)
        if case .deny(_, let name) = res {
            XCTAssertEqual(name, "DestructiveGuardian")
        } else { XCTFail("expected deny") }

        persona = DestructiveGuardianPersona(handler: StubGuardianHandler { _, _ in HTTPResponse(status: 200, body: Data("oops".utf8)) })
        res = await persona.evaluate(request)
        if case .escalate(let reason, let name) = res {
            XCTAssertEqual(name, "DestructiveGuardian")
            XCTAssertTrue(reason.contains("invalid"))
        } else { XCTFail("expected escalate") }

        struct TestError: Error {}
        persona = DestructiveGuardianPersona(handler: StubGuardianHandler { _, _ in throw TestError() })
        res = await persona.evaluate(request)
        if case .escalate(let reason, let name) = res {
            XCTAssertEqual(name, "DestructiveGuardian")
            XCTAssertTrue(reason.contains("error"))
        } else { XCTFail("expected escalate on error") }
    }
}

