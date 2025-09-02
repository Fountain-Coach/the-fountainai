import Foundation

public struct updateNLSearchModelParameters: Codable {
    public let modelid: String
}

public struct updateNLSearchModel: APIRequest {
    public typealias Body = NLSearchModelUpdateSchema
    public typealias Response = NLSearchModelSchema
    public var method: String { "PUT" }
    public var parameters: updateNLSearchModelParameters
    public var path: String {
        var path = "/nl_search_models/{modelId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{modelId}", with: String(parameters.modelid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: updateNLSearchModelParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
