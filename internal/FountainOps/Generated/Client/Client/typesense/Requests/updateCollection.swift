import Foundation

public struct updateCollectionParameters: Codable {
    public let collectionname: String
}

public struct updateCollection: APIRequest {
    public typealias Body = CollectionUpdateSchema
    public typealias Response = CollectionUpdateSchema
    public var method: String { "PATCH" }
    public var parameters: updateCollectionParameters
    public var path: String {
        var path = "/collections/{collectionName}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{collectionName}", with: String(parameters.collectionname))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: updateCollectionParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
