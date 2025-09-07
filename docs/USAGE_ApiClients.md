API Clients Usage

- ApiClientsCore: shared HTTP + JSON.
- GatewayAPI: Gateway health and metrics.
- PersistAPI: Capabilities, corpora, functions, reflections.
- SemanticBrowserAPI: Segments, entities, pages, export, health.
- LLMGatewayAPI: Chat and metrics.

Examples

```
import GatewayAPI
import PersistAPI
import SemanticBrowserAPI
import LLMGatewayAPI

@main
struct Demo {
    static func main() async throws {
        let gateway = GatewayClient(baseURL: URL(string: "http://gateway.local")!)
        let _ = try await gateway.health()

        let persist = PersistClient(baseURL: URL(string: "http://persist.local")!, apiKey: ProcessInfo.processInfo.environment["FOUNTAINSTORE_API_KEY"])
        let caps = try await persist.capabilities()
        print(caps)

        let sem = SemanticBrowserClient(baseURL: URL(string: "http://semantic-browser.local")!)
        let segs = try await sem.querySegments(q: "swift")
        print("segments: \(segs.total)")

        let llm = LLMGatewayClient(baseURL: URL(string: "http://llm-gateway.fountain.coach/api/v1")!)
        let res = try await llm.chat(.init(model: "gpt-4o-mini", messages: [.init(role: "user", content: "Hello")]))
        print(res)
    }
}
```

Regeneration

- The manifest `docs/gui_endpoints.json` tracks the endpoints mapped for GUI milestones.
- Run `swift Scripts/generate-api-clients.swift` (placeholder) or extend it to emit code.

