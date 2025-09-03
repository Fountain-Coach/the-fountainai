import Foundation

public enum PersistenceError: Error, Equatable {
    case invalidData
}

public actor FountainStoreClient {
    private let client: FountainStoreClientProtocol

    public init(client: FountainStoreClientProtocol) {
        self.client = client
    }

    // MARK: - Corpus
    public func createCorpus(_ id: String, metadata: [String: String] = [:]) async throws -> CorpusResponse {
        try await client.createCorpus(id: id, metadata: metadata)
        return CorpusResponse(corpusId: id, message: "created")
    }

    public func createCorpus(_ req: CorpusCreateRequest) async throws -> CorpusResponse {
        try await createCorpus(req.corpusId)
    }

    public func getCorpus(_ id: String) async throws -> Corpus? {
        try await client.getCorpus(id: id)
    }

    public func deleteCorpus(_ id: String) async throws {
        try await client.deleteCorpus(id: id)
    }

    public func listCorpora(limit: Int = 50, offset: Int = 0) async throws -> (total: Int, corpora: [String]) {
        try await client.listCorpora(limit: limit, offset: offset)
    }

    // MARK: - Documents
    public func putDoc(corpusId: String, collection: String, id: String, body: Data) async throws {
        try await client.putDoc(corpusId: corpusId, collection: collection, id: id, body: body)
    }

    public func getDoc(corpusId: String, collection: String, id: String) async throws -> Data? {
        try await client.getDoc(corpusId: corpusId, collection: collection, id: id)
    }

    public func deleteDoc(corpusId: String, collection: String, id: String) async throws {
        try await client.deleteDoc(corpusId: corpusId, collection: collection, id: id)
    }

    public func query(corpusId: String, collection: String, query: Query) async throws -> QueryResponse {
        try await client.query(corpusId: corpusId, collection: collection, query: query)
    }

    // MARK: - Capabilities
    public func capabilities() async throws -> Capabilities {
        try await client.capabilities()
    }

    // MARK: - Admin
    public func snapshot(corpusId: String) async throws { try await client.snapshot(corpusId: corpusId) }
    public func restore(corpusId: String) async throws { try await client.restore(corpusId: corpusId) }
    public func backup(corpusId: String) async throws { try await client.backup(corpusId: corpusId) }
    public func compaction(corpusId: String) async throws { try await client.compaction(corpusId: corpusId) }

    // MARK: - Convenience Helpers
    public func addPage(_ page: Page) async throws -> SuccessResponse {
        let payload = try JSONEncoder().encode(page)
        try await putDoc(corpusId: page.corpusId, collection: "pages", id: page.pageId, body: payload)
        return SuccessResponse(message: "ok")
    }

    public func listPages(corpusId: String, limit: Int = 50, offset: Int = 0) async throws -> (total: Int, pages: [Page]) {
        let q = Query(filters: ["corpusId": corpusId], limit: limit, offset: offset)
        let resp = try await query(corpusId: corpusId, collection: "pages", query: q)
        let list = try resp.documents.map { try JSONDecoder().decode(Page.self, from: $0) }
        return (resp.total, list)
    }

    public func addSegment(_ segment: Segment) async throws -> SuccessResponse {
        let payload = try JSONEncoder().encode(segment)
        try await putDoc(corpusId: segment.corpusId, collection: "segments", id: segment.segmentId, body: payload)
        return SuccessResponse(message: "ok")
    }

    public func listSegments(corpusId: String, limit: Int = 50, offset: Int = 0) async throws -> (total: Int, segments: [Segment]) {
        let q = Query(filters: ["corpusId": corpusId], limit: limit, offset: offset)
        let resp = try await query(corpusId: corpusId, collection: "segments", query: q)
        let list = try resp.documents.map { try JSONDecoder().decode(Segment.self, from: $0) }
        return (resp.total, list)
    }

    public func addEntity(_ entity: Entity) async throws -> SuccessResponse {
        let payload = try JSONEncoder().encode(entity)
        try await putDoc(corpusId: entity.corpusId, collection: "entities", id: entity.entityId, body: payload)
        return SuccessResponse(message: "ok")
    }

    public func listEntities(corpusId: String, limit: Int = 50, offset: Int = 0) async throws -> (total: Int, entities: [Entity]) {
        let q = Query(filters: ["corpusId": corpusId], limit: limit, offset: offset)
        let resp = try await query(corpusId: corpusId, collection: "entities", query: q)
        let list = try resp.documents.map { try JSONDecoder().decode(Entity.self, from: $0) }
        return (resp.total, list)
    }

    public func addTable(_ table: Table) async throws -> SuccessResponse {
        let payload = try JSONEncoder().encode(table)
        try await putDoc(corpusId: table.corpusId, collection: "tables", id: table.tableId, body: payload)
        return SuccessResponse(message: "ok")
    }

    public func listTables(corpusId: String, limit: Int = 50, offset: Int = 0) async throws -> (total: Int, tables: [Table]) {
        let q = Query(filters: ["corpusId": corpusId], limit: limit, offset: offset)
        let resp = try await query(corpusId: corpusId, collection: "tables", query: q)
        let list = try resp.documents.map { try JSONDecoder().decode(Table.self, from: $0) }
        return (resp.total, list)
    }

    public func addAnalysis(_ analysis: AnalysisRecord) async throws -> SuccessResponse {
        let payload = try JSONEncoder().encode(analysis)
        try await putDoc(corpusId: analysis.corpusId, collection: "analyses", id: analysis.analysisId, body: payload)
        return SuccessResponse(message: "ok")
    }

    public func listAnalyses(corpusId: String, limit: Int = 50, offset: Int = 0) async throws -> (total: Int, analyses: [AnalysisRecord]) {
        let q = Query(filters: ["corpusId": corpusId], limit: limit, offset: offset)
        let resp = try await query(corpusId: corpusId, collection: "analyses", query: q)
        let list = try resp.documents.map { try JSONDecoder().decode(AnalysisRecord.self, from: $0) }
        return (resp.total, list)
    }

    public func addBaseline(_ baseline: Baseline) async throws -> SuccessResponse {
        let payload = try JSONEncoder().encode(baseline)
        try await putDoc(corpusId: baseline.corpusId, collection: "baselines", id: baseline.baselineId, body: payload)
        return SuccessResponse(message: "ok")
    }

    public func listBaselines(corpusId: String, limit: Int = 50, offset: Int = 0) async throws -> (total: Int, baselines: [Baseline]) {
        let q = Query(filters: ["corpusId": corpusId], limit: limit, offset: offset)
        let resp = try await query(corpusId: corpusId, collection: "baselines", query: q)
        let list = try resp.documents.map { try JSONDecoder().decode(Baseline.self, from: $0) }
        return (resp.total, list)
    }

    public func addReflection(_ reflection: Reflection) async throws -> SuccessResponse {
        let payload = try JSONEncoder().encode(reflection)
        try await putDoc(corpusId: reflection.corpusId, collection: "reflections", id: reflection.reflectionId, body: payload)
        return SuccessResponse(message: "ok")
    }

    public func listReflections(corpusId: String, limit: Int = 50, offset: Int = 0) async throws -> (total: Int, reflections: [Reflection]) {
        let q = Query(filters: ["corpusId": corpusId], limit: limit, offset: offset)
        let resp = try await query(corpusId: corpusId, collection: "reflections", query: q)
        let list = try resp.documents.map { try JSONDecoder().decode(Reflection.self, from: $0) }
        return (resp.total, list)
    }

    public func addDrift(_ drift: Drift) async throws -> SuccessResponse {
        let payload = try JSONEncoder().encode(drift)
        try await putDoc(corpusId: drift.corpusId, collection: "drifts", id: drift.driftId, body: payload)
        return SuccessResponse(message: "ok")
    }

    public func listDrifts(corpusId: String, limit: Int = 50, offset: Int = 0) async throws -> (total: Int, drifts: [Drift]) {
        let q = Query(filters: ["corpusId": corpusId], limit: limit, offset: offset)
        let resp = try await query(corpusId: corpusId, collection: "drifts", query: q)
        let list = try resp.documents.map { try JSONDecoder().decode(Drift.self, from: $0) }
        return (resp.total, list)
    }

    public func addPatterns(_ patterns: Patterns) async throws -> SuccessResponse {
        let payload = try JSONEncoder().encode(patterns)
        try await putDoc(corpusId: patterns.corpusId, collection: "patterns", id: patterns.patternsId, body: payload)
        return SuccessResponse(message: "ok")
    }

    public func listPatterns(corpusId: String, limit: Int = 50, offset: Int = 0) async throws -> (total: Int, patterns: [Patterns]) {
        let q = Query(filters: ["corpusId": corpusId], limit: limit, offset: offset)
        let resp = try await query(corpusId: corpusId, collection: "patterns", query: q)
        let list = try resp.documents.map { try JSONDecoder().decode(Patterns.self, from: $0) }
        return (resp.total, list)
    }

    public func addRole(_ role: Role) async throws -> SuccessResponse {
        let payload = try JSONEncoder().encode(role)
        try await putDoc(corpusId: role.corpusId, collection: "roles", id: role.name, body: payload)
        return SuccessResponse(message: "ok")
    }

    public func seedDefaultRoles(corpusId: String, defaults: [Role]) async throws -> SuccessResponse {
        for role in defaults { _ = try await addRole(role) }
        return SuccessResponse(message: "seeded")
    }

    public func addFunction(_ function: FunctionModel) async throws -> SuccessResponse {
        let payload = try JSONEncoder().encode(function)
        try await putDoc(corpusId: function.corpusId, collection: "functions", id: function.functionId, body: payload)
        return SuccessResponse(message: "ok")
    }

    public func listFunctions(limit: Int = 50, offset: Int = 0, q: String? = nil) async throws -> (total: Int, functions: [FunctionModel]) {
        let resp = try await query(corpusId: "", collection: "functions", query: Query())
        var list = try resp.documents.map { try JSONDecoder().decode(FunctionModel.self, from: $0) }
        if let q = q, !q.isEmpty, q != "*" {
            let needle = q.lowercased()
            list = list.filter { fn in
                [fn.name, fn.description, fn.httpPath, fn.functionId, fn.corpusId]
                    .contains { $0.lowercased().contains(needle) }
            }
        }
        let total = list.count
        let slice = Array(list.dropFirst(min(offset, total)).prefix(limit))
        return (total, slice)
    }

    public func getFunctionDetails(functionId: String) async throws -> FunctionModel? {
        let resp = try await query(corpusId: "", collection: "functions", query: Query(mode: .byId(functionId)))
        return resp.documents.first.flatMap { try? JSONDecoder().decode(FunctionModel.self, from: $0) }
    }

    public func listFunctions(corpusId: String, limit: Int = 50, offset: Int = 0, q: String? = nil) async throws -> (total: Int, functions: [FunctionModel]) {
        let qobj = Query(filters: ["corpusId": corpusId])
        let resp = try await query(corpusId: corpusId, collection: "functions", query: qobj)
        var list = try resp.documents.map { try JSONDecoder().decode(FunctionModel.self, from: $0) }
        if let q = q, !q.isEmpty, q != "*" {
            let needle = q.lowercased()
            list = list.filter { fn in
                [fn.name, fn.description, fn.httpPath, fn.functionId, fn.corpusId]
                    .contains { $0.lowercased().contains(needle) }
            }
        }
        let total = list.count
        let slice = Array(list.dropFirst(min(offset, total)).prefix(limit))
        return (total, slice)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

