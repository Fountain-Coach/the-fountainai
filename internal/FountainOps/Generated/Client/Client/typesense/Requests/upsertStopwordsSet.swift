import Foundation

public struct upsertStopwordsSetParameters: Codable {
    public let setid: String
}

public struct upsertStopwordsSet: APIRequest {
    public typealias Body = StopwordsSetUpsertSchema
    public typealias Response = StopwordsSetSchema
    public var method: String { "PUT" }
    public var parameters: upsertStopwordsSetParameters
    public var path: String {
        var path = "/stopwords/{setId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{setId}", with: String(parameters.setid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: upsertStopwordsSetParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
