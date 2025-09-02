import Foundation

public struct deleteConversationModelParameters: Codable {
    public let modelid: String
}

public struct deleteConversationModel: APIRequest {
    public typealias Body = NoBody
    public typealias Response = ConversationModelSchema
    public var method: String { "DELETE" }
    public var parameters: deleteConversationModelParameters
    public var path: String {
        var path = "/conversations/models/{modelId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{modelId}", with: String(parameters.modelid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: deleteConversationModelParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
