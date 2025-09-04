import XCTest
import Foundation
import NIOCore
import NIOHTTP1
import AsyncHTTPClient
import FountainRuntime
@testable import SecuritySentinelGatewayPlugin

final class LLMSecuritySentinelClientTests: XCTestCase {
    override func tearDown() async throws {
        unsetenv("SEC_SENTINEL_URL")
        unsetenv("SEC_SENTINEL_API_KEY")
        unsetenv("SEC_SENTINEL_TIMEOUT_MS")
        unsetenv("SEC_SENTINEL_RETRIES")
        unsetenv("SEC_SENTINEL_MODEL")
    }

    func startServer(_ handler: @escaping (HTTPRequest) -> HTTPResponse) async throws -> (Int, NIOHTTPServer) {
        let kernel = HTTPKernel(route: handler)
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)
        return (port, server)
    }

    func testConsultSuccessWithRetry() async throws {
        var first = true
        let (port, server) = try await startServer { _ in
            if first {
                first = false
                return HTTPResponse(status: 500)
            } else {
                let body = Data("{\"decision\":\"allow\",\"reason\":\"ok\",\"confidence\":0.1,\"model\":\"m\",\"requestID\":\"id\"}".utf8)
                return HTTPResponse(status: 200, body: body)
            }
        }

        setenv("SEC_SENTINEL_URL", "http://127.0.0.1:\(port)", 1)
        setenv("SEC_SENTINEL_API_KEY", "k", 1)
        setenv("SEC_SENTINEL_TIMEOUT_MS", "50", 1)
        setenv("SEC_SENTINEL_RETRIES", "1", 1)
        setenv("SEC_SENTINEL_MODEL", "m", 1)

        let client = LLMSecuritySentinelClient()
        let decision = try await client.consult(summary: "s", context: nil)
        XCTAssertEqual(decision.decision, .allow)
        XCTAssertEqual(decision.model, "m")
        try await server.stop()

        _ = SentinelClientFactory.make()
    }

    func testConsultReturnsUnavailableOn4xx() async throws {
        let (port, server) = try await startServer { _ in
            HTTPResponse(status: 403)
        }

        setenv("SEC_SENTINEL_URL", "http://127.0.0.1:\(port)", 1)
        setenv("SEC_SENTINEL_API_KEY", "k", 1)
        setenv("SEC_SENTINEL_TIMEOUT_MS", "50", 1)
        setenv("SEC_SENTINEL_RETRIES", "0", 1)

        let client = LLMSecuritySentinelClient()
        let decision = try await client.consult(summary: "s", context: nil)
        XCTAssertEqual(decision.decision, .deny)
        XCTAssertEqual(decision.reason, "LLM unavailable")
        try await server.stop()
    }

    func testCircuitBreakerOpens() async throws {
        setenv("SEC_SENTINEL_URL", "http://127.0.0.1:1", 1)
        setenv("SEC_SENTINEL_API_KEY", "k", 1)
        setenv("SEC_SENTINEL_TIMEOUT_MS", "10", 1)
        setenv("SEC_SENTINEL_RETRIES", "0", 1)

        let client = LLMSecuritySentinelClient()
        for _ in 0..<3 {
            let decision = try await client.consult(summary: "s", context: nil)
            XCTAssertEqual(decision.decision, .deny)
        }
        let start = Date()
        let finalDecision = try await client.consult(summary: "s", context: nil)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 0.05)
        XCTAssertEqual(finalDecision.decision, .deny)
    }
}
