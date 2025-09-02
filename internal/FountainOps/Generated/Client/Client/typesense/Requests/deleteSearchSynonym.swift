import Foundation

public struct deleteSearchSynonymParameters: Codable {
    public let collectionname: String
    public let synonymid: String
}

public struct deleteSearchSynonym: APIRequest {
    public typealias Body = NoBody
    public typealias Response = SearchSynonymDeleteResponse
    public var method: String { "DELETE" }
    public var parameters: deleteSearchSynonymParameters
    public var path: String {
        var path = "/collections/{collectionName}/synonyms/{synonymId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{collectionName}", with: String(parameters.collectionname))
        path = path.replacingOccurrences(of: "{synonymId}", with: String(parameters.synonymid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: deleteSearchSynonymParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
