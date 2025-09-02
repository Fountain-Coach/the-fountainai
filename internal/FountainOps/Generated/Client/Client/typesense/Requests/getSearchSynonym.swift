import Foundation

public struct getSearchSynonymParameters: Codable {
    public let collectionname: String
    public let synonymid: String
}

public struct getSearchSynonym: APIRequest {
    public typealias Body = NoBody
    public typealias Response = SearchSynonym
    public var method: String { "GET" }
    public var parameters: getSearchSynonymParameters
    public var path: String {
        var path = "/collections/{collectionName}/synonyms/{synonymId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{collectionName}", with: String(parameters.collectionname))
        path = path.replacingOccurrences(of: "{synonymId}", with: String(parameters.synonymid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: getSearchSynonymParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
