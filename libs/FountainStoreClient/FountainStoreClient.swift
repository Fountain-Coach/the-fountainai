import Foundation

public enum PersistenceError: Error, Equatable {
    case invalidData
}

public actor FountainStoreClient {
    private let client: FountainStoreClientProtocol

    public init(client: FountainStoreClientProtocol) {
        self.client = client
    }

    // MARK: - Collections
    public func ensureCollections() async {
        try? await client.createCollection(name: "corpora", fields: [("corpusId", "string")], defaultSortingField: "corpusId")
        try? await client.createCollection(name: "baselines", fields: [("corpusId", "string"), ("baselineId", "string"), ("content", "string"), ("ts", "float")], defaultSortingField: "baselineId")
        try? await client.createCollection(name: "reflections", fields: [("corpusId", "string"), ("reflectionId", "string"), ("question", "string"), ("content", "string"), ("ts", "float")], defaultSortingField: "reflectionId")
        try? await client.createCollection(name: "drifts", fields: [("corpusId", "string"), ("driftId", "string"), ("content", "string"), ("ts", "float")], defaultSortingField: "driftId")
        try? await client.createCollection(name: "patterns", fields: [("corpusId", "string"), ("patternsId", "string"), ("content", "string"), ("ts", "float")], defaultSortingField: "patternsId")
        try? await client.createCollection(name: "roles", fields: [("corpusId", "string"), ("name", "string"), ("prompt", "string")], defaultSortingField: "name")
        try? await client.createCollection(name: "functions", fields: [("corpusId", "string"), ("functionId", "string"), ("name", "string"), ("description", "string"), ("httpMethod", "string"), ("httpPath", "string")], defaultSortingField: "functionId")
    }

    // MARK: - Corpora
    public func createCorpus(_ req: CorpusCreateRequest) async throws -> CorpusResponse {
        await ensureCollections()
        let payload = try JSONEncoder().encode(["corpusId": req.corpusId])
        try await client.upsert(collectionName: "corpora", document: payload)
        return CorpusResponse(corpusId: req.corpusId, message: "created")
    }

    public func listCorpora(limit: Int = 50, offset: Int = 0) async throws -> (total: Int, corpora: [String]) {
        await ensureCollections()
        let data = try await client.exportAll(collectionName: "corpora")
        let items: [[String: Any]] = Self.parseJSONL(data)
        let ids = items.compactMap { $0["corpusId"] as? String }.sorted()
        let total = ids.count
        let slice = Array(ids.dropFirst(min(offset, total)).prefix(limit))
        return (total, slice)
    }

    // MARK: - Baselines
    public func addBaseline(_ baseline: Baseline) async throws -> SuccessResponse {
        await ensureCollections()
        let payload = try JSONEncoder().encode(baseline)
        try await client.upsert(collectionName: "baselines", document: payload)
        return SuccessResponse(message: "ok")
    }

    public func listBaselines(corpusId: String, limit: Int = 50, offset: Int = 0) async throws -> (total: Int, baselines: [Baseline]) {
        await ensureCollections()
        let data = try await client.exportAll(collectionName: "baselines")
        let items: [[String: Any]] = Self.parseJSONL(data)
        let filtered = items.filter { ($0["corpusId"] as? String) == corpusId }
        let decoded: [Baseline] = try filtered.map { try Self.decode($0) }
        let total = decoded.count
        let slice = Array(decoded.dropFirst(min(offset, total)).prefix(limit))
        return (total, slice)
     }

    // MARK: - Reflections
    public func addReflection(_ reflection: Reflection) async throws -> SuccessResponse {
        await ensureCollections()
        let payload = try JSONEncoder().encode(reflection)
        try await client.upsert(collectionName: "reflections", document: payload)
        return SuccessResponse(message: "ok")
    }

    public func listReflections(corpusId: String, limit: Int = 50, offset: Int = 0) async throws -> (total: Int, reflections: [Reflection]) {
        await ensureCollections()
        let data = try await client.exportAll(collectionName: "reflections")
        let items: [[String: Any]] = Self.parseJSONL(data)
        let filtered = items.filter { ($0["corpusId"] as? String) == corpusId }
        let decoded: [Reflection] = try filtered.map { try Self.decode($0) }
        let total = decoded.count
        let slice = Array(decoded.dropFirst(min(offset, total)).prefix(limit))
        return (total, slice)
     }

    // MARK: - Drifts
    public func listDrifts(corpusId: String, limit: Int = 50, offset: Int = 0) async throws -> (total: Int, drifts: [Drift]) {
        await ensureCollections()
        let data = try await client.exportAll(collectionName: "drifts")
        let items: [[String: Any]] = Self.parseJSONL(data)
        let filtered = items.filter { ($0["corpusId"] as? String) == corpusId }
        let decoded: [Drift] = try filtered.map { try Self.decode($0) }
        let total = decoded.count
        let slice = Array(decoded.dropFirst(min(offset, total)).prefix(limit))
        return (total, slice)
    }

    // MARK: - Patterns
    public func listPatterns(corpusId: String, limit: Int = 50, offset: Int = 0) async throws -> (total: Int, patterns: [Patterns]) {
        await ensureCollections()
        let data = try await client.exportAll(collectionName: "patterns")
        let items: [[String: Any]] = Self.parseJSONL(data)
        let filtered = items.filter { ($0["corpusId"] as? String) == corpusId }
        let decoded: [Patterns] = try filtered.map { try Self.decode($0) }
        let total = decoded.count
        let slice = Array(decoded.dropFirst(min(offset, total)).prefix(limit))
        return (total, slice)
    }

    // MARK: - Drift
    public func addDrift(_ drift: Drift) async throws -> SuccessResponse {
        await ensureCollections()
        let payload = try JSONEncoder().encode(drift)
        try await client.upsert(collectionName: "drifts", document: payload)
        return SuccessResponse(message: "ok")
    }

    // MARK: - Patterns
    public func addPatterns(_ patterns: Patterns) async throws -> SuccessResponse {
        await ensureCollections()
        let payload = try JSONEncoder().encode(patterns)
        try await client.upsert(collectionName: "patterns", document: payload)
        return SuccessResponse(message: "ok")
    }

    // MARK: - Roles
    public func addRole(_ role: Role) async throws -> SuccessResponse {
        await ensureCollections()
        let payload = try JSONEncoder().encode(role)
        try await client.upsert(collectionName: "roles", document: payload)
        return SuccessResponse(message: "ok")
    }

    public func seedDefaultRoles(corpusId: String, defaults: [Role]) async throws -> SuccessResponse {
        for role in defaults { _ = try await addRole(role) }
        return SuccessResponse(message: "seeded")
    }

    // MARK: - Functions
    public func addFunction(_ function: FunctionModel) async throws -> SuccessResponse {
        await ensureCollections()
        let payload = try JSONEncoder().encode(function)
        try await client.upsert(collectionName: "functions", document: payload)
        return SuccessResponse(message: "ok")
    }

    public func listFunctions(limit: Int = 50, offset: Int = 0, q: String? = nil) async throws -> (total: Int, functions: [FunctionModel]) {
        await ensureCollections()
        let page = max(offset / max(limit, 1) + 1, 1)
        let perPage = max(limit, 1)
        let (total, results) = try await client.searchFunctions(q: (q?.isEmpty == false ? q! : "*"), filterBy: nil, page: page, perPage: perPage)
        return (total, results)
    }

    public func getFunctionDetails(functionId: String) async throws -> FunctionModel? {
        let (_, list) = try await listFunctions(limit: Int.max, offset: 0)
        return list.first { $0.functionId == functionId }
    }

    public func listFunctions(corpusId: String, limit: Int = 50, offset: Int = 0, q: String? = nil) async throws -> (total: Int, functions: [FunctionModel]) {
        await ensureCollections()
        let page = max(offset / max(limit, 1) + 1, 1)
        let perPage = max(limit, 1)
        let filterBy = "corpusId:=\(corpusId)"
        let (total, results) = try await client.searchFunctions(q: (q?.isEmpty == false ? q! : "*"), filterBy: filterBy, page: page, perPage: perPage)
        return (total, results)
    }

    // MARK: - Helpers
    static func parseJSONL(_ data: Data) -> [[String: Any]] {
        let str = String(data: data, encoding: .utf8) ?? ""
        var out: [[String: Any]] = []
        for line in str.split(separator: "\n") {
            if let d = String(line).data(using: .utf8), let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any] {
                out.append(obj)
            }
        }
        return out
    }

    static func decode<T: Decodable>(_ obj: [String: Any]) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: obj)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
