import Foundation

public struct getSearchSynonymsParameters: Codable {
    public let collectionname: String
}

public struct getSearchSynonyms: APIRequest {
    public typealias Body = NoBody
    public typealias Response = SearchSynonymsResponse
    public var method: String { "GET" }
    public var parameters: getSearchSynonymsParameters
    public var path: String {
        var path = "/collections/{collectionName}/synonyms"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{collectionName}", with: String(parameters.collectionname))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: getSearchSynonymsParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
