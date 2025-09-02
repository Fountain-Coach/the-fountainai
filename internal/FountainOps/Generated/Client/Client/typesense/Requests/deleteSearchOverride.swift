import Foundation

public struct deleteSearchOverrideParameters: Codable {
    public let collectionname: String
    public let overrideid: String
}

public struct deleteSearchOverride: APIRequest {
    public typealias Body = NoBody
    public typealias Response = SearchOverrideDeleteResponse
    public var method: String { "DELETE" }
    public var parameters: deleteSearchOverrideParameters
    public var path: String {
        var path = "/collections/{collectionName}/overrides/{overrideId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{collectionName}", with: String(parameters.collectionname))
        path = path.replacingOccurrences(of: "{overrideId}", with: String(parameters.overrideid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: deleteSearchOverrideParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
