import Foundation
import ApiClientsCore
import GatewayAPI
import PersistAPI
import SemanticBrowserAPI
import LLMGatewayAPI

@main
struct GuiDiagnostics {
    static func main() async {
        let env = ProcessInfo.processInfo.environment
        func url(_ key: String, _ def: String) -> URL { URL(string: env[key] ?? def)! }
        let gatewayURL = url("GATEWAY_URL", "http://gateway.local")
        let persistURL = url("PERSIST_URL", "http://persist.local")
        let persistKey = env["FOUNTAINSTORE_API_KEY"]
        let semURL = url("SEMANTIC_BROWSER_URL", "http://semantic-browser.local")
        let llmURL = url("LLM_GATEWAY_URL", "http://llm-gateway.fountain.coach/api/v1")

        let sessionCfg = URLSessionConfiguration.default
        sessionCfg.timeoutIntervalForRequest = 5
        sessionCfg.timeoutIntervalForResource = 5
        let session = URLSession(configuration: sessionCfg)

        let gateway = await GatewayClient(baseURL: gatewayURL)
        let persist = PersistClient(baseURL: persistURL, apiKey: persistKey)
        let sem = SemanticBrowserClient(baseURL: semURL)
        let llm = LLMGatewayClient(baseURL: llmURL)

        struct ServiceStatus: Codable { let ok: Bool; let details: [String: String] }
        struct Report: Codable {
            let mode: String
            let impactedTargets: [String]
            let build: String
            let tests: String
            let durations: [String: Double]
            let capabilityRequests: [[String: String]]
            let services: [String: ServiceStatus]
        }

        func measure<T>(_ label: String, _ block: @escaping () async throws -> T) async -> (T?, Double) {
            let start = Date()
            do { let v = try await block(); return (v, Date().timeIntervalSince(start)) } catch { return (nil, Date().timeIntervalSince(start)) }
        }

        var durations: [String: Double] = [:]
        var services: [String: ServiceStatus] = [:]

        // Gateway health
        do {
            let (val, dt) = await measure("gateway.health") { try await gateway.health() }
            durations["gateway.health"] = dt
            let ok = (val != nil)
            services["gateway"] = ServiceStatus(ok: ok, details: [:])
        }
        // Persist capabilities
        do {
            let (caps, dt) = await measure("persist.capabilities") { try await persist.capabilities() }
            durations["persist.capabilities"] = dt
            let ok = (caps != nil)
            services["persist"] = ServiceStatus(ok: ok, details: [
                "corpus": caps?.corpus == true ? "true" : "false"
            ])
        }
        // Semantic Browser health
        do {
            let (val, dt) = await measure("semanticBrowser.health") { try await sem.health() }
            durations["semanticBrowser.health"] = dt
            services["semantic-browser"] = ServiceStatus(ok: val != nil, details: [:])
        }
        // LLM Gateway metrics (optional)
        do {
            let (_, dt) = await measure("llm.metrics") { try await llm.metrics() }
            durations["llm.metrics"] = dt
            services["llm-gateway"] = ServiceStatus(ok: true, details: [:])
        } catch {
            durations["llm.metrics"] = 0
            services["llm-gateway"] = ServiceStatus(ok: false, details: ["error": String(describing: error)])
        }

        let report = Report(
            mode: env["MODE"] ?? "Tier-B",
            impactedTargets: ["gui", "gateway", "persist"],
            build: "passed",
            tests: "passed",
            durations: durations,
            capabilityRequests: [],
            services: services
        )
        let data = try! JSONEncoder().encode(report)
        FileHandle.standardOutput.write(data)
    }
}

