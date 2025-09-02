import Foundation

public struct getCollectionParameters: Codable {
    public let collectionname: String
}

public struct getCollection: APIRequest {
    public typealias Body = NoBody
    public typealias Response = CollectionResponse
    public var method: String { "GET" }
    public var parameters: getCollectionParameters
    public var path: String {
        var path = "/collections/{collectionName}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{collectionName}", with: String(parameters.collectionname))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: getCollectionParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
