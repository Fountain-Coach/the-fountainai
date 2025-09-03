import Foundation
import FountainStore

/// Embedded implementation of ``FountainStoreClientProtocol`` backed by
/// the pure Swift `FountainStore`.
public final actor EmbeddedFountainStoreClient: FountainStoreClientProtocol {
    private struct StoredDoc: Codable, Identifiable { var id: String; var body: Data }

    private let root: URL
    private let caps: Capabilities
    private var stores: [String: FountainStore] = [:]
    private var corpusMeta: [String: [String: String]] = [:]

    /// Creates a client rooted at the given filesystem path. If `path` is
    /// omitted a unique temporary directory is used.
    public init(path: String? = nil, caps: Capabilities = Capabilities(
        corpus: true,
        documents: ["upsert", "get", "delete"],
        query: ["byId", "byIndexEq", "prefixScan", "filters", "sort"],
        transactions: ["snapshot", "restore"],
        admin: ["health", "backup", "compaction", "metrics"],
        experimental: []
    )) {
        if let p = path {
            self.root = URL(fileURLWithPath: p)
        } else {
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
            self.root = tmp
        }
        self.caps = caps
    }

    private func store(for corpusId: String) async throws -> FountainStore {
        if let s = stores[corpusId] { return s }
        let dir = corpusId.isEmpty ? "_global" : corpusId
        let url = root.appendingPathComponent(dir)
        let st = try await FountainStore.open(.init(path: url))
        stores[corpusId] = st
        return st
    }

    // MARK: - Corpus
    public func createCorpus(id: String, metadata: [String: String]) async throws {
        let url = root.appendingPathComponent(id)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        corpusMeta[id] = metadata
        _ = try await store(for: id)
    }

    public func getCorpus(id: String) async throws -> Corpus? {
        guard let meta = corpusMeta[id] else { return nil }
        return Corpus(id: id, metadata: meta)
    }

    public func deleteCorpus(id: String) async throws {
        let url = root.appendingPathComponent(id)
        try? FileManager.default.removeItem(at: url)
        stores[id] = nil
        corpusMeta.removeValue(forKey: id)
    }

    public func listCorpora(limit: Int, offset: Int) async throws -> (total: Int, corpora: [String]) {
        let ids = Array(corpusMeta.keys).sorted()
        let total = ids.count
        let slice = Array(ids.dropFirst(min(offset, total)).prefix(limit))
        return (total, slice)
    }

    // MARK: - Documents
    public func putDoc(corpusId: String, collection: String, id: String, body: Data) async throws {
        let st = try await store(for: corpusId)
        let coll = await st.collection(collection, of: StoredDoc.self)
        try await coll.put(.init(id: id, body: body))
    }

    public func getDoc(corpusId: String, collection: String, id: String) async throws -> Data? {
        let st = try await store(for: corpusId)
        let coll = await st.collection(collection, of: StoredDoc.self)
        return try await coll.get(id: id)?.body
    }

    public func deleteDoc(corpusId: String, collection: String, id: String) async throws {
        let st = try await store(for: corpusId)
        let coll = await st.collection(collection, of: StoredDoc.self)
        try await coll.delete(id: id)
    }

    public func query(corpusId: String, collection: String, query: Query) async throws -> QueryResponse {
        let st = try await store(for: corpusId)
        let coll = await st.collection(collection, of: StoredDoc.self)

        var docs: [Data]
        if let mode = query.mode {
            switch mode {
            case .byId(let id):
                if let d = try await coll.get(id: id) {
                    return QueryResponse(total: 1, documents: [d.body])
                } else {
                    return QueryResponse(total: 0, documents: [])
                }
            case .byIndexEq(let field, let value):
                let all = try await coll.scan()
                docs = all.filter { decode($0.body)[field] as? String == value }.map { $0.body }
            case .prefixScan(let field, let prefix):
                let all = try await coll.scan()
                docs = all.filter { (decode($0.body)[field] as? String)?.hasPrefix(prefix) == true }.map { $0.body }
            }
        } else {
            docs = try await coll.scan().map { $0.body }
        }

        if !query.filters.isEmpty {
            docs = docs.filter { data in
                let obj = decode(data)
                for (k, v) in query.filters { if (obj[k] as? String) != v { return false } }
                return true
            }
        }

        if let first = query.sort.first {
            let field = first.field
            let asc = first.ascending
            docs.sort { a, b in
                let av = decode(a)[field] as? String ?? ""
                let bv = decode(b)[field] as? String ?? ""
                return asc ? (av < bv) : (av > bv)
            }
        }

        let total = docs.count
        let offset = min(query.offset ?? 0, total)
        let limit = query.limit ?? total
        let slice = Array(docs.dropFirst(offset).prefix(limit))
        return QueryResponse(total: total, documents: slice)
    }

    private func decode(_ data: Data) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    // MARK: - Capabilities
    public func capabilities() async throws -> Capabilities { caps }

    // MARK: - Admin
    public func snapshot(corpusId: String) async throws {
        let src = root.appendingPathComponent(corpusId)
        let dst = root.appendingPathComponent("\(corpusId).snapshot")
        let fm = FileManager.default
        if fm.fileExists(atPath: dst.path) { try fm.removeItem(at: dst) }
        try fm.copyItem(at: src, to: dst)
    }

    public func restore(corpusId: String) async throws {
        let src = root.appendingPathComponent("\(corpusId).snapshot")
        let dst = root.appendingPathComponent(corpusId)
        let fm = FileManager.default
        guard fm.fileExists(atPath: src.path) else { return }
        if fm.fileExists(atPath: dst.path) { try fm.removeItem(at: dst) }
        try fm.copyItem(at: src, to: dst)
        stores[corpusId] = try await FountainStore.open(.init(path: dst))
    }

    public func backup(corpusId: String) async throws {}
    public func compaction(corpusId: String) async throws {}
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

