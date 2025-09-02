import Foundation

public struct getSearchOverridesParameters: Codable {
    public let collectionname: String
}

public struct getSearchOverrides: APIRequest {
    public typealias Body = NoBody
    public typealias Response = SearchOverridesResponse
    public var method: String { "GET" }
    public var parameters: getSearchOverridesParameters
    public var path: String {
        var path = "/collections/{collectionName}/overrides"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{collectionName}", with: String(parameters.collectionname))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: getSearchOverridesParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
