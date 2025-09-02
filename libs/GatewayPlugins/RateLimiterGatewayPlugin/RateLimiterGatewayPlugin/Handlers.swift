import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import FountainRuntime

/// Handlers for rate limiter gateway endpoints using an LLM backend.
public actor Handlers {
    private let client = LLMPluginClient(personaPath: "openapi/personas/rate-limiter.md")
    private let defaultLimit: Int

    public init(defaultLimit: Int = 60) {
        self.defaultLimit = defaultLimit
    }

    /// Returns whether the request is within its rate limit.
    public func allow(routeId: String, clientId: String, limitPerMinute: Int?) async -> Bool {
        let req = RateLimitCheckRequest(routeId: routeId,
                                        clientId: clientId,
                                        limitPerMinute: limitPerMinute ?? defaultLimit)
        let prompt = (try? String(data: JSONEncoder().encode(req), encoding: .utf8)) ?? ""
        guard
            let result = try? await client.call(prompt: prompt),
            let data = result.data(using: .utf8),
            let resp = try? JSONDecoder().decode(RateLimitCheckResponse.self, from: data)
        else {
            return false
        }
        return resp.allowed
    }

    /// Returns aggregate allowance statistics.
    public func stats() async -> (allowed: Int, throttled: Int) {
        guard
            let result = try? await client.call(prompt: "stats"),
            let data = result.data(using: .utf8),
            let resp = try? JSONDecoder().decode(RateLimitStatsResponse.self, from: data)
        else {
            return (0, 0)
        }
        return (resp.allowed, resp.throttled)
    }

    /// Delegates rate limit checks to the LLM via HTTP.
    public func rateLimitCheck(_ request: HTTPRequest, body: RateLimitCheckRequest?) async throws -> HTTPResponse {
        let allowed = await allow(routeId: body?.routeId ?? "",
                                  clientId: body?.clientId ?? "",
                                  limitPerMinute: body?.limitPerMinute)
        let resp = RateLimitCheckResponse(allowed: allowed)
        let json = try JSONEncoder().encode(resp)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: json)
    }

    /// Requests aggregated statistics from the LLM via HTTP.
    public func rateLimitStats(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let s = await stats()
        let resp = RateLimitStatsResponse(allowed: s.allowed, throttled: s.throttled)
        let json = try JSONEncoder().encode(resp)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: json)
    }
}

/// Minimal client that forwards prompts and persona to the LLM Gateway.
struct LLMPluginClient {
    let persona: String
    let url: URL

    init(personaPath: String,
         url: URL = URL(string: ProcessInfo.processInfo.environment["LLM_GATEWAY_URL"] ?? "http://localhost:8080/chat")!) {
        self.persona = (try? String(contentsOfFile: personaPath, encoding: .utf8)) ?? ""
        self.url = url
    }

    func call(prompt: String) async throws -> String {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = ["persona": persona, "prompt": prompt]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, _) = try await URLSession.shared.data(for: req)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
