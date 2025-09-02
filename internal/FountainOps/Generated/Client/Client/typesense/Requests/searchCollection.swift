import Foundation

public struct searchCollectionParameters: Codable {
    public let collectionname: String
    public let searchparameters: SearchParameters
}

public struct searchCollection: APIRequest {
    public typealias Body = NoBody
    public typealias Response = SearchResult
    public var method: String { "GET" }
    public var parameters: searchCollectionParameters
    public var path: String {
        var path = "/collections/{collectionName}/documents/search"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{collectionName}", with: String(parameters.collectionname))
        query.append("searchParameters=\(parameters.searchparameters)")
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: searchCollectionParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
