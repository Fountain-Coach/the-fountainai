import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private struct CorpusCreateRequest: Codable {
    let corpusId: String
}

private struct BaselineList: Codable {
    let total: Int
    let baselines: [Baseline]
}

/// Optional remote Typesense configuration loaded from the environment.
/// When `TYPESENSE_URL` is set the client will persist data using HTTP
/// requests instead of the in-memory store.

/// Minimal in-memory representation of a Typesense service used for testing.
/// This allows the Persistence and Function Caller services to share state
/// without requiring an external dependency.
public actor TypesenseClient {
    public static let shared = TypesenseClient()

    private let baseURL: URL?
    private let apiKey: String?
    private let functionsCacheURL: URL?

    private var corpora: Set<String> = []
    private var functions: [String: Function] = [:]
    private var baselines: [String: [String: Baseline]] = [:]
    private var drifts: [String: [String: Drift]] = [:]
    private var patterns: [String: [String: Patterns]] = [:]
    private var reflections: [String: [String: Reflection]] = [:]
    private var roles: [String: [String: Role]] = [:]

    private func saveCache() {
        guard let url = functionsCacheURL else { return }
        if let data = try? JSONEncoder().encode(functions) {
            try? data.write(to: url)
        }
    }

    private init() {
        if let path = ProcessInfo.processInfo.environment["FUNCTIONS_CACHE_PATH"] {
            self.functionsCacheURL = URL(fileURLWithPath: path)
            if let data = try? Data(contentsOf: self.functionsCacheURL!),
               let cached = try? JSONDecoder().decode([String: Function].self, from: data) {
                self.functions = cached
            }
        } else {
            self.functionsCacheURL = URL(fileURLWithPath: "functions-cache.json")
            if let data = try? Data(contentsOf: self.functionsCacheURL!),
               let cached = try? JSONDecoder().decode([String: Function].self, from: data) {
                self.functions = cached
            }
        }
        if let url = ProcessInfo.processInfo.environment["TYPESENSE_URL"] {
            self.baseURL = URL(string: url)
            self.apiKey = ProcessInfo.processInfo.environment["TYPESENSE_API_KEY"]
        } else {
            self.baseURL = nil
            self.apiKey = nil
        }
    }

    private func request(path: String, method: String, body: Data?) async throws -> Data {
        guard let baseURL = baseURL else { return Data() }
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = method
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey { req.setValue(apiKey, forHTTPHeaderField: "X-API-Key") }
        let (data, _) = try await URLSession.shared.data(for: req)
        return data
    }

    // MARK: - Corpora
    public func createCorpus(id: String) async -> CorpusResponse {
        if let _ = baseURL {
            let body = try? JSONEncoder().encode(CorpusCreateRequest(corpusId: id))
            if let data = try? await request(path: "corpora", method: "POST", body: body),
               let resp = try? JSONDecoder().decode(CorpusResponse.self, from: data) {
                return resp
            }
            return CorpusResponse(corpusId: id, message: "created")
        }
        corpora.insert(id)
        return CorpusResponse(corpusId: id, message: "created")
    }

    public func listCorpora() async -> [String] {
        if let _ = baseURL {
            if let data = try? await request(path: "corpora", method: "GET", body: nil),
               let resp = try? JSONDecoder().decode([String].self, from: data) {
                return resp
            }
            return []
        }
        return Array(corpora)
    }

    // MARK: - Functions
    public func addFunction(_ fn: Function) async {
        var fn = fn
        if fn.parametersSchema == nil {
            fn = Function(description: fn.description,
                         functionId: fn.functionId,
                         httpMethod: fn.httpMethod,
                         httpPath: fn.httpPath,
                         name: fn.name,
                         parametersSchema: "{}")
        }
        if let _ = baseURL {
            let body = try? JSONEncoder().encode(fn)
            _ = try? await request(path: "functions", method: "POST", body: body)
            functions[fn.functionId] = fn
            saveCache()
        } else {
            functions[fn.functionId] = fn
            saveCache()
        }
    }

    public func listFunctions() async -> [Function] {
        if let _ = baseURL {
            if let data = try? await request(path: "functions", method: "GET", body: nil),
               let resp = try? JSONDecoder().decode([Function].self, from: data) {
                for fn in resp { functions[fn.functionId] = fn }
                saveCache()
                return resp
            }
            return []
        }
        return Array(functions.values)
    }

    public func functionDetails(id: String) async -> Function? {
        if let _ = baseURL {
            if let data = try? await request(path: "functions/\(id)", method: "GET", body: nil),
               let fn = try? JSONDecoder().decode(Function.self, from: data) {
                functions[id] = fn
                saveCache()
                return fn
            }
            return nil
        }
        return functions[id]
    }

    // MARK: - Baseline Data
    public func addBaseline(_ baseline: Baseline) async {
        if let _ = baseURL {
            let body = try? JSONEncoder().encode(baseline)
            _ = try? await request(path: "corpora/\(baseline.corpusId)/baselines", method: "POST", body: body)
        } else {
            var items = baselines[baseline.corpusId] ?? [:]
            items[baseline.baselineId] = baseline
            baselines[baseline.corpusId] = items
        }
    }

    public func addDrift(_ drift: Drift) async {
        if let _ = baseURL {
            let body = try? JSONEncoder().encode(drift)
            _ = try? await request(path: "corpora/\(drift.corpusId)/drifts", method: "POST", body: body)
        } else {
            var items = drifts[drift.corpusId] ?? [:]
            items[drift.driftId] = drift
            drifts[drift.corpusId] = items
        }
    }

    public func addPatterns(_ patternsReq: Patterns) async {
        if let _ = baseURL {
            let body = try? JSONEncoder().encode(patternsReq)
            _ = try? await request(path: "corpora/\(patternsReq.corpusId)/patterns", method: "POST", body: body)
        } else {
            var items = patterns[patternsReq.corpusId] ?? [:]
            items[patternsReq.patternsId] = patternsReq
            patterns[patternsReq.corpusId] = items
        }
    }

    // MARK: - Roles
    public func addRole(_ role: Role) async {
        if let _ = baseURL {
            let body = try? JSONEncoder().encode(role)
            _ = try? await request(path: "corpora/\(role.corpusId)/roles", method: "POST", body: body)
        } else {
            var items = roles[role.corpusId] ?? [:]
            items[role.name] = role
            roles[role.corpusId] = items
        }
    }

    public func listRoles(for corpusId: String) async -> [Role] {
        if let _ = baseURL {
            if let data = try? await request(path: "corpora/\(corpusId)/roles", method: "GET", body: nil),
               let resp = try? JSONDecoder().decode([Role].self, from: data) {
                return resp
            }
            return []
        }
        if let dict = roles[corpusId] {
            return Array(dict.values)
        }
        return []
    }

    public func addReflection(_ reflection: Reflection) async {
        if let _ = baseURL {
            let body = try? JSONEncoder().encode(reflection)
            _ = try? await request(path: "corpora/\(reflection.corpusId)/reflections", method: "POST", body: body)
        } else {
            var items = reflections[reflection.corpusId] ?? [:]
            items[reflection.reflectionId] = reflection
            reflections[reflection.corpusId] = items
        }
    }

    public func reflectionCount(for corpusId: String) async -> Int {
        if let _ = baseURL {
            if let data = try? await request(path: "corpora/\(corpusId)/reflections", method: "GET", body: nil),
               let resp = try? JSONDecoder().decode([String: Int].self, from: data),
               let count = resp["total"] {
                return count
            }
            return 0
        }
        return reflections[corpusId]?.count ?? 0
    }

    public func listBaselines(for corpusId: String) async -> [Baseline] {
        if let _ = baseURL {
            if let data = try? await request(path: "corpora/\(corpusId)/baselines", method: "GET", body: nil),
               let resp = try? JSONDecoder().decode(BaselineList.self, from: data) {
                return resp.baselines
            }
            return []
        }
        if let dict = baselines[corpusId] {
            return Array(dict.values)
        }
        return []
    }

    public func baselineCount(for corpusId: String) async -> Int {
        if let _ = baseURL {
            if let data = try? await request(path: "corpora/\(corpusId)/baselines", method: "GET", body: nil),
               let resp = try? JSONDecoder().decode([String: Int].self, from: data),
               let count = resp["total"] {
                return count
            }
            return 0
        }
        return baselines[corpusId]?.count ?? 0
    }

    public func driftCount(for corpusId: String) async -> Int {
        if let _ = baseURL {
            if let data = try? await request(path: "corpora/\(corpusId)/drifts", method: "GET", body: nil),
               let resp = try? JSONDecoder().decode([String: Int].self, from: data),
               let count = resp["total"] {
                return count
            }
            return 0
        }
        return drifts[corpusId]?.count ?? 0
    }

    public func patternsCount(for corpusId: String) async -> Int {
        if let _ = baseURL {
            if let data = try? await request(path: "corpora/\(corpusId)/patterns", method: "GET", body: nil),
               let resp = try? JSONDecoder().decode([String: Int].self, from: data),
               let count = resp["total"] {
                return count
            }
            return 0
        }
        return patterns[corpusId]?.count ?? 0
    }

    public func latestReflection(for corpusId: String) async -> Reflection? {
        if let _ = baseURL {
            if let data = try? await request(path: "corpora/\(corpusId)/reflections", method: "GET", body: nil),
               let items = try? JSONDecoder().decode([Reflection].self, from: data) {
                return items.last
            }
            return nil
        }
        if let dict = reflections[corpusId] {
            return Array(dict.values).last
        }
        return nil
    }

    public func historyCount(for corpusId: String) async -> Int {
        if let _ = baseURL {
            var total = 0
            if let data = try? await request(path: "corpora/\(corpusId)/baselines", method: "GET", body: nil),
               let resp = try? JSONDecoder().decode([String: Int].self, from: data),
               let count = resp["total"] { total += count }
            if let data = try? await request(path: "corpora/\(corpusId)/drifts", method: "GET", body: nil),
               let resp = try? JSONDecoder().decode([String: Int].self, from: data),
               let count = resp["total"] { total += count }
            if let data = try? await request(path: "corpora/\(corpusId)/patterns", method: "GET", body: nil),
               let resp = try? JSONDecoder().decode([String: Int].self, from: data),
               let count = resp["total"] { total += count }
            if let data = try? await request(path: "corpora/\(corpusId)/reflections", method: "GET", body: nil),
               let resp = try? JSONDecoder().decode([String: Int].self, from: data),
               let count = resp["total"] { total += count }
            return total
        }
        let b = baselines[corpusId]?.count ?? 0
        let d = drifts[corpusId]?.count ?? 0
        let p = patterns[corpusId]?.count ?? 0
        let r = reflections[corpusId]?.count ?? 0
        return b + d + p + r
    }

    /// Clears all stored data. Tests call this to avoid state leakage.
    public func reset() async {
        corpora.removeAll()
        functions.removeAll()
        baselines.removeAll()
        drifts.removeAll()
        patterns.removeAll()
        reflections.removeAll()
        roles.removeAll()
        saveCache()
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
