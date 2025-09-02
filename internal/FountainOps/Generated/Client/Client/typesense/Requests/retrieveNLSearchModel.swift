import Foundation

public struct retrieveNLSearchModelParameters: Codable {
    public let modelid: String
}

public struct retrieveNLSearchModel: APIRequest {
    public typealias Body = NoBody
    public typealias Response = NLSearchModelSchema
    public var method: String { "GET" }
    public var parameters: retrieveNLSearchModelParameters
    public var path: String {
        var path = "/nl_search_models/{modelId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{modelId}", with: String(parameters.modelid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: retrieveNLSearchModelParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
