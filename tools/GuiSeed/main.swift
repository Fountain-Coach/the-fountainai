import Foundation
import PersistAPI

@main
struct GuiSeed {
    static func main() async {
        let env = ProcessInfo.processInfo.environment
        func get(_ key: String, _ def: String) -> String { env[key] ?? def }
        let persistURL = URL(string: get("PERSIST_URL", "http://persist.local"))!
        let apiKey = env["FOUNTAINSTORE_API_KEY"]

        let corpusId = get("CORPUS_ID", "gui")
        let baselineId = get("BASELINE_ID", "baseline-1")
        let baselineContent = get("BASELINE_CONTENT", "Initial baseline seeded by gui-seed")
        let reflectionId = get("REFLECTION_ID", "refl-1")
        let reflectionQ = get("REFLECTION_Q", "What is the GUI MVP?")
        let reflectionA = get("REFLECTION_A", "Corpus browser + detail with FTS.")

        let persist = PersistClient(baseURL: persistURL, apiKey: apiKey)

        struct Outcome: Codable { let steps: [String: String] }
        var steps: [String: String] = [:]

        // Create corpus (idempotent-ish)
        do {
            let _ = try await persist.createCorpus(.init(corpusId: corpusId))
            steps["createCorpus"] = "ok"
        } catch {
            steps["createCorpus"] = "skip: \(error)"
        }

        // Add baseline
        do {
            let ack = try await persist.addBaseline(corpusId: corpusId, baseline: .init(baselineId: baselineId, corpusId: corpusId, content: baselineContent))
            steps["addBaseline"] = ack.message
        } catch {
            steps["addBaseline"] = "error: \(error)"
        }

        // Add reflection
        do {
            let ack = try await persist.addReflection(corpusId: corpusId, reflection: .init(reflectionId: reflectionId, corpusId: corpusId, question: reflectionQ, content: reflectionA))
            steps["addReflection"] = ack.message
        } catch {
            steps["addReflection"] = "error: \(error)"
        }

        let result = Outcome(steps: steps)
        let data = try! JSONEncoder().encode(result)
        FileHandle.standardOutput.write(data)
    }
}

