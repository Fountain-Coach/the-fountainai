import Foundation

public struct deleteStopwordsSetParameters: Codable {
    public let setid: String
}

public struct deleteStopwordsSet: APIRequest {
    public typealias Body = NoBody
    public typealias Response = deleteStopwordsSetResponse
    public var method: String { "DELETE" }
    public var parameters: deleteStopwordsSetParameters
    public var path: String {
        var path = "/stopwords/{setId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{setId}", with: String(parameters.setid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: deleteStopwordsSetParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
