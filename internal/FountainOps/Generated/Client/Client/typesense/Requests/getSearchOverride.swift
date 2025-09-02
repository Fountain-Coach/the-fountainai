import Foundation

public struct getSearchOverrideParameters: Codable {
    public let collectionname: String
    public let overrideid: String
}

public struct getSearchOverride: APIRequest {
    public typealias Body = NoBody
    public typealias Response = SearchOverride
    public var method: String { "GET" }
    public var parameters: getSearchOverrideParameters
    public var path: String {
        var path = "/collections/{collectionName}/overrides/{overrideId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{collectionName}", with: String(parameters.collectionname))
        path = path.replacingOccurrences(of: "{overrideId}", with: String(parameters.overrideid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: getSearchOverrideParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
