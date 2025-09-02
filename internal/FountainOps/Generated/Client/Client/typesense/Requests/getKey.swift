import Foundation

public struct getKeyParameters: Codable {
    public let keyid: Int
}

public struct getKey: APIRequest {
    public typealias Body = NoBody
    public typealias Response = ApiKey
    public var method: String { "GET" }
    public var parameters: getKeyParameters
    public var path: String {
        var path = "/keys/{keyId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{keyId}", with: String(parameters.keyid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: getKeyParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
