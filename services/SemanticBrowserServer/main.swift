import Foundation
import SemanticBrowser
import LauncherSignature

verifyLauncherSignature()

func buildService() -> SemanticMemoryService {
    return SemanticMemoryService()
}

let env = ProcessInfo.processInfo.environment
Task {
    let service = buildService()
    let engine: BrowserEngine = {
        if let ws = env["SB_CDP_URL"], let u = URL(string: ws) { return CDPBrowserEngine(wsURL: u) }
        if let bin = env["SB_BROWSER_CLI"] {
            return ShellBrowserEngine(
                binary: bin,
                args: (env["SB_BROWSER_ARGS"] ?? "").split(separator: " ").map(String.init)
            )
        }
        return URLFetchBrowserEngine()
    }()
    let requireKey = (env["SB_REQUIRE_API_KEY"] ?? "true").lowercased() != "false"
    let kernel = makeSemanticKernel(service: service, engine: engine, requireAPIKey: requireKey)
    let server = NIOHTTPServer(kernel: kernel)
    _ = try? await server.start(port: 8006)
    print("semantic-browser listening on 8006")
}
RunLoop.main.run()

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
