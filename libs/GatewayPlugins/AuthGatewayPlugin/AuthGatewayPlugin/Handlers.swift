import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import FountainRuntime

/// Collection of handlers for auth gateway endpoints backed by an LLM.
public actor Handlers {
    private let client = LLMPluginClient(personaPath: "openapi/personas/auth.md")

    public init() {}

    /// Delegates validation to the LLM using the Auth persona.
    public func authValidate(_ request: HTTPRequest, body: ValidateRequest?) async throws -> HTTPResponse {
        let prompt = body.flatMap { try? String(data: JSONEncoder().encode($0), encoding: .utf8) } ?? ""
        let result = (try? await client.call(prompt: prompt)) ?? "{}"
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: Data(result.utf8))
    }

    /// Retrieves claims for the supplied token via the LLM.
    public func authClaims(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let token = request.headers["Authorization"] ?? ""
        let result = (try? await client.call(prompt: token)) ?? "{}"
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: Data(result.utf8))
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
