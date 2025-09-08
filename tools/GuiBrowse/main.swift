import Foundation
import Dispatch
import PersistAPI
import SemanticBrowserAPI

private func run() async {
        let args = Array(CommandLine.arguments.dropFirst())
        guard args.count >= 1 else {
            print("Usage: gui-browse <corpora|segments|entities|get-page> [options]\n" +
                  "Examples:\n  gui-browse corpora\n  gui-browse segments q=swift limit=10\n  gui-browse entities q=FountainAI type=ORG\n  gui-browse get-page id=<PAGE_ID>")
            return
        }

        let env = ProcessInfo.processInfo.environment
        let persistURL = URL(string: env["PERSIST_URL"] ?? "http://persist.local")!
        let semURL = URL(string: env["SEMANTIC_BROWSER_URL"] ?? "http://semantic-browser.local")!
        let apiKey = env["FOUNTAINSTORE_API_KEY"]

        let persist = PersistClient(baseURL: persistURL, apiKey: apiKey)
        let sem = SemanticBrowserClient(baseURL: semURL)

        func kv(_ s: String) -> (String, String)? {
            let parts = s.split(separator: "=", maxSplits: 1).map(String.init)
            return parts.count == 2 ? (parts[0], parts[1]) : nil
        }
        let cmd = args[0]
        let opts = Dictionary(uniqueKeysWithValues: args.dropFirst().compactMap(kv))

        switch cmd {
        case "corpora":
            do { let r = try await persist.listCorpora(); print(String(data: try JSONEncoder().encode(r), encoding: .utf8)!) } catch { print("error: \(error)") }
        case "segments":
            do {
                let r = try await sem.querySegments(q: opts["q"], kind: opts["kind"], entity: opts["entity"], limit: Int(opts["limit"] ?? "20") ?? 20, offset: Int(opts["offset"] ?? "0") ?? 0)
                print(String(data: try JSONEncoder().encode(r), encoding: .utf8)!)
            } catch { print("error: \(error)") }
        case "entities":
            do {
                let r = try await sem.queryEntities(q: opts["q"], type: opts["type"], limit: Int(opts["limit"] ?? "20") ?? 20, offset: Int(opts["offset"] ?? "0") ?? 0)
                print(String(data: try JSONEncoder().encode(r), encoding: .utf8)!)
            } catch { print("error: \(error)") }
        case "get-page":
            guard let id = opts["id"] else { print("id is required"); return }
            do { let r = try await sem.getPage(id: id); print(String(data: try JSONEncoder().encode(r), encoding: .utf8)!) } catch { print("error: \(error)") }
        default:
            print("unknown command: \(cmd)")
        }
}

// Top-level entry for async support
let semaphore = DispatchSemaphore(value: 0)
Task {
    await run()
    semaphore.signal()
}
semaphore.wait()
