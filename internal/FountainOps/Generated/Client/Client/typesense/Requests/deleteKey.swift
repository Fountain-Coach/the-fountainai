import Foundation

public struct deleteKeyParameters: Codable {
    public let keyid: Int
}

public struct deleteKey: APIRequest {
    public typealias Body = NoBody
    public typealias Response = ApiKeyDeleteResponse
    public var method: String { "DELETE" }
    public var parameters: deleteKeyParameters
    public var path: String {
        var path = "/keys/{keyId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{keyId}", with: String(parameters.keyid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: deleteKeyParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
