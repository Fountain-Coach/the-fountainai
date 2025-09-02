import Foundation

public struct updateConversationModelParameters: Codable {
    public let modelid: String
}

public struct updateConversationModel: APIRequest {
    public typealias Body = ConversationModelUpdateSchema
    public typealias Response = ConversationModelSchema
    public var method: String { "PUT" }
    public var parameters: updateConversationModelParameters
    public var path: String {
        var path = "/conversations/models/{modelId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{modelId}", with: String(parameters.modelid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: updateConversationModelParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
