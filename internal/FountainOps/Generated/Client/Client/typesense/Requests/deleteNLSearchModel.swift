import Foundation

public struct deleteNLSearchModelParameters: Codable {
    public let modelid: String
}

public struct deleteNLSearchModel: APIRequest {
    public typealias Body = NoBody
    public typealias Response = NLSearchModelDeleteSchema
    public var method: String { "DELETE" }
    public var parameters: deleteNLSearchModelParameters
    public var path: String {
        var path = "/nl_search_models/{modelId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{modelId}", with: String(parameters.modelid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: deleteNLSearchModelParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
