import Foundation

public protocol FountainStoreClientProtocol: Sendable {
    // MARK: - Corpus
    func createCorpus(id: String, metadata: [String: String]) async throws
    func getCorpus(id: String) async throws -> Corpus?
    func deleteCorpus(id: String) async throws
    func listCorpora(limit: Int, offset: Int) async throws -> (total: Int, corpora: [String])

    // MARK: - Documents
    func putDoc(corpusId: String, collection: String, id: String, body: Data) async throws
    func getDoc(corpusId: String, collection: String, id: String) async throws -> Data?
    func deleteDoc(corpusId: String, collection: String, id: String) async throws
    func query(corpusId: String, collection: String, query: Query) async throws -> QueryResponse

    // MARK: - Capabilities
    func capabilities() async throws -> Capabilities

    // MARK: - Admin
    func snapshot(corpusId: String) async throws
    func restore(corpusId: String) async throws
    func backup(corpusId: String) async throws
    func compaction(corpusId: String) async throws
}

public final class MockFountainStoreClient: FountainStoreClientProtocol, @unchecked Sendable {
    private struct StoredCorpus { var metadata: [String: String]; var collections: [String: [String: Data]] }
    private var corpora: [String: StoredCorpus] = [:]
    private var snapshots: [String: StoredCorpus] = [:]

    public init() {}

    // MARK: - Corpus
    public func createCorpus(id: String, metadata: [String: String]) async throws {
        if corpora[id] == nil { corpora[id] = StoredCorpus(metadata: metadata, collections: [:]) }
    }

    public func getCorpus(id: String) async throws -> Corpus? {
        guard let c = corpora[id] else { return nil }
        return Corpus(id: id, metadata: c.metadata)
    }

    public func deleteCorpus(id: String) async throws {
        corpora.removeValue(forKey: id)
    }

    public func listCorpora(limit: Int, offset: Int) async throws -> (total: Int, corpora: [String]) {
        let ids = corpora.keys.sorted()
        let total = ids.count
        let slice = Array(ids.dropFirst(min(offset, total)).prefix(limit))
        return (total, slice)
    }

    // MARK: - Documents
    public func putDoc(corpusId: String, collection: String, id: String, body: Data) async throws {
        var corpus = corpora[corpusId] ?? StoredCorpus(metadata: [:], collections: [:])
        var coll = corpus.collections[collection] ?? [:]
        coll[id] = body
        corpus.collections[collection] = coll
        corpora[corpusId] = corpus
    }

    public func getDoc(corpusId: String, collection: String, id: String) async throws -> Data? {
        if corpusId.isEmpty {
            for corpus in corpora.values {
                if let data = corpus.collections[collection]?[id] { return data }
            }
            return nil
        }
        return corpora[corpusId]?.collections[collection]?[id]
    }

    public func deleteDoc(corpusId: String, collection: String, id: String) async throws {
        if corpusId.isEmpty {
            for key in corpora.keys {
                corpora[key]?.collections[collection]?[id] = nil
            }
        } else {
            corpora[corpusId]?.collections[collection]?[id] = nil
        }
    }

    public func query(corpusId: String, collection: String, query: Query) async throws -> QueryResponse {
        var docs: [Data] = []
        if corpusId.isEmpty {
            for corpus in corpora.values {
                if let coll = corpus.collections[collection] {
                    docs.append(contentsOf: coll.values)
                }
            }
        } else if let coll = corpora[corpusId]?.collections[collection] {
            docs.append(contentsOf: coll.values)
        }

        func decode(_ data: Data) -> [String: Any] {
            (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        }

        if let mode = query.mode {
            switch mode {
            case .byId(let id):
                if let data = try await getDoc(corpusId: corpusId, collection: collection, id: id) {
                    return QueryResponse(total: 1, documents: [data])
                } else { return QueryResponse(total: 0, documents: []) }
            case .byIndexEq(let field, let value):
                docs = docs.filter { decode($0)[field] as? String == value }
            case .prefixScan(let field, let prefix):
                docs = docs.filter { (decode($0)[field] as? String)?.hasPrefix(prefix) == true }
            }
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

    // MARK: - Capabilities
    public func capabilities() async throws -> Capabilities {
        Capabilities(
            corpus: true,
            documents: ["upsert", "get", "delete"],
            query: ["byId", "byIndexEq", "prefixScan", "filters", "sort"],
            transactions: ["snapshot", "restore"],
            admin: ["health", "backup", "compaction", "metrics"],
            experimental: []
        )
    }

    // MARK: - Admin
    public func snapshot(corpusId: String) async throws {
        if let c = corpora[corpusId] { snapshots[corpusId] = c }
    }

    public func restore(corpusId: String) async throws {
        if let snap = snapshots[corpusId] { corpora[corpusId] = snap }
    }

    public func backup(corpusId: String) async throws {}

    public func compaction(corpusId: String) async throws {}
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

