import Foundation

public struct getStemmingDictionaryParameters: Codable {
    public let dictionaryid: String
}

public struct getStemmingDictionary: APIRequest {
    public typealias Body = NoBody
    public typealias Response = StemmingDictionary
    public var method: String { "GET" }
    public var parameters: getStemmingDictionaryParameters
    public var path: String {
        var path = "/stemming/dictionaries/{dictionaryId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{dictionaryId}", with: String(parameters.dictionaryid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: getStemmingDictionaryParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
