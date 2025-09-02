import Foundation

public struct retrieveConversationModelParameters: Codable {
    public let modelid: String
}

public struct retrieveConversationModel: APIRequest {
    public typealias Body = NoBody
    public typealias Response = ConversationModelSchema
    public var method: String { "GET" }
    public var parameters: retrieveConversationModelParameters
    public var path: String {
        var path = "/conversations/models/{modelId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{modelId}", with: String(parameters.modelid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: retrieveConversationModelParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
