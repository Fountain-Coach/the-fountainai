import Foundation
import PersistAPI

@main
struct GuiCapabilities {
    static func main() async {
        let env = ProcessInfo.processInfo.environment
        let persistURL = URL(string: env["PERSIST_URL"] ?? "http://persist.local")!
        let apiKey = env["FOUNTAINSTORE_API_KEY"]
        let persist = PersistClient(baseURL: persistURL, apiKey: apiKey)
        do {
            let caps = try await persist.capabilities()
            let data = try JSONEncoder().encode(caps)
            FileHandle.standardOutput.write(data)
        } catch {
            FileHandle.standardError.write(Data("error: \(error)\n".utf8))
            exit(2)
        }
    }
}

