import Foundation

public struct importStemmingDictionaryParameters: Codable {
    public let id: String
}

public struct importStemmingDictionary: APIRequest {
    public typealias Body = importStemmingDictionaryRequest
    public typealias Response = Data
    public var method: String { "POST" }
    public var parameters: importStemmingDictionaryParameters
    public var path: String {
        var path = "/stemming/dictionaries/import"
        var query: [String] = []
        query.append("id=\(parameters.id)")
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: importStemmingDictionaryParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
