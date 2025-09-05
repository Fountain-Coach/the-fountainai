import Foundation
import FountainStoreClient

@main
struct IngestConfig {
    static func main() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let store = ConfigurationStore.fromEnvironment(env) else {
            fputs("FOUNTAINSTORE_URL, FOUNTAINSTORE_API_KEY, and corpus id required\n", stderr)
            return
        }
        let base = URL(fileURLWithPath: "Configuration", isDirectory: true)
        let fm = FileManager.default
        let items = ["gateway.yml", "curator.yml", "publishing.yml", "roleguard.yml", "routes.json"]
        for name in items {
            let path = base.appendingPathComponent(name)
            if fm.fileExists(atPath: path.path), let data = try? Data(contentsOf: path) {
                try await store.put(name, data: data)
                print("ingested \(name)")
            }
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
