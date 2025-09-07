import Foundation
import ApiClientsCore

public struct PageDoc: Codable, Sendable, Equatable { public var id: String }
public struct SegmentDoc: Codable, Sendable, Equatable { public var id: String }
public struct EntityDoc: Codable, Sendable, Equatable { public var id: String }

public struct ListResponse<T: Codable & Sendable & Equatable>: Codable, Sendable, Equatable {
    public var total: Int
    public var items: [T]
}

public actor SemanticBrowserClient {
    private let http: RESTClient

    public init(baseURL: URL, apiKey: String? = nil) {
        var headers: [String: String] = ["Accept": "application/json"]
        if let apiKey = apiKey { headers["X-API-Key"] = apiKey }
        self.http = RESTClient(baseURL: baseURL, defaultHeaders: headers)
    }

    // GET /v1/segments
    public func querySegments(q: String? = nil, kind: String? = nil, entity: String? = nil, limit: Int = 20, offset: Int = 0) async throws -> ListResponse<SegmentDoc> {
        var query: [String: String?] = ["limit": String(limit), "offset": String(offset)]
        query["q"] = q
        query["kind"] = kind
        query["entity"] = entity
        guard let url = http.buildURL(path: "/v1/segments", query: query) else { throw APIError.invalidURL }
        let resp = try await http.send(APIRequest(method: .GET, url: url))
        return try JSONDecoder().decode(ListResponse<SegmentDoc>.self, from: resp.data)
    }

    // GET /v1/entities
    public func queryEntities(q: String? = nil, type: String? = nil, limit: Int = 20, offset: Int = 0) async throws -> ListResponse<EntityDoc> {
        var query: [String: String?] = ["limit": String(limit), "offset": String(offset)]
        query["q"] = q
        query["type"] = type
        guard let url = http.buildURL(path: "/v1/entities", query: query) else { throw APIError.invalidURL }
        let resp = try await http.send(APIRequest(method: .GET, url: url))
        return try JSONDecoder().decode(ListResponse<EntityDoc>.self, from: resp.data)
    }

    // GET /v1/pages/{id}
    public func getPage(id: String) async throws -> PageDoc {
        guard let url = http.buildURL(path: "/v1/pages/\(id)") else { throw APIError.invalidURL }
        let resp = try await http.send(APIRequest(method: .GET, url: url))
        return try JSONDecoder().decode(PageDoc.self, from: resp.data)
    }

    // GET /v1/export
    public func exportArtifacts(pageId: String, format: String) async throws -> Data {
        let query: [String: String?] = ["pageId": pageId, "format": format]
        guard let url = http.buildURL(path: "/v1/export", query: query) else { throw APIError.invalidURL }
        let resp = try await http.send(APIRequest(method: .GET, url: url))
        return resp.data
    }

    // GET /v1/health
    public func health() async throws -> JSONValue {
        guard let url = http.buildURL(path: "/v1/health") else { throw APIError.invalidURL }
        let resp = try await http.send(APIRequest(method: .GET, url: url))
        return try JSONDecoder().decode(JSONValue.self, from: resp.data)
    }
}

