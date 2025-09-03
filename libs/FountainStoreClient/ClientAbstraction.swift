import Foundation

public protocol FountainStoreClientProtocol: Sendable {
    func createCollection(name: String, fields: [(String, String)], defaultSortingField: String?) async throws
    func upsert(collectionName: String, document: Data) async throws
    func exportAll(collectionName: String) async throws -> Data
    func searchFunctions(q: String, filterBy: String?, page: Int, perPage: Int) async throws -> (total: Int, functions: [FunctionModel])
}

public final class MockFountainStoreClient: FountainStoreClientProtocol, @unchecked Sendable {
    public private(set) var collections: [String: [[String: Any]]] = [:]

    public init() {}

    public func createCollection(name: String, fields: [(String, String)], defaultSortingField: String?) async throws {
        if collections[name] == nil { collections[name] = [] }
    }

    public func upsert(collectionName: String, document: Data) async throws {
        let obj = try JSONSerialization.jsonObject(with: document) as? [String: Any] ?? [:]
        var list = collections[collectionName] ?? []
        let preferredKeys = ["functionId", "baselineId", "reflectionId", "corpusId", "id"]
        let idKey = preferredKeys.first(where: { obj[$0] is String }) ?? obj.keys.first(where: { $0.hasSuffix("Id") || $0 == "id" })
        if let idKey, let id = obj[idKey] as? String, !id.isEmpty {
            if let idx = list.firstIndex(where: { ($0[idKey] as? String) == id }) {
                list[idx] = obj
            } else {
                list.append(obj)
            }
        } else {
            list.append(obj)
        }
        collections[collectionName] = list
    }

    public func exportAll(collectionName: String) async throws -> Data {
        let list = collections[collectionName] ?? []
        let lines = try list.map { try JSONSerialization.data(withJSONObject: $0) }.map { String(data: $0, encoding: .utf8) ?? "{}" }
        return Data(lines.joined(separator: "\n").utf8)
    }

    public func searchFunctions(q: String, filterBy: String?, page: Int, perPage: Int) async throws -> (total: Int, functions: [FunctionModel]) {
        let all = collections["functions"] ?? []
        let needle = q == "*" ? nil : q.lowercased()
        let filtered: [[String: Any]] = all.filter { obj in
            if let fb = filterBy, fb.hasPrefix("corpusId:=") {
                let val = String(fb.dropFirst("corpusId:=".count))
                if (obj["corpusId"] as? String) != val { return false }
            }
            if let needle {
                let fields = ["name","description","httpPath","functionId","corpusId"]
                return fields.contains { key in (obj[key] as? String)?.lowercased().contains(needle) == true }
            }
            return true
        }
        let decoded: [FunctionModel] = try filtered.map { data in
            let d = try JSONSerialization.data(withJSONObject: data)
            return try JSONDecoder().decode(FunctionModel.self, from: d)
        }.sorted { $0.functionId < $1.functionId }
        let start = max((page - 1) * perPage, 0)
        let slice = Array(decoded.dropFirst(min(start, decoded.count)).prefix(perPage))
        return (decoded.count, slice)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
