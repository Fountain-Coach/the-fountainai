import Foundation

public struct retrieveStopwordsSetParameters: Codable {
    public let setid: String
}

public struct retrieveStopwordsSet: APIRequest {
    public typealias Body = NoBody
    public typealias Response = StopwordsSetRetrieveSchema
    public var method: String { "GET" }
    public var parameters: retrieveStopwordsSetParameters
    public var path: String {
        var path = "/stopwords/{setId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{setId}", with: String(parameters.setid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: retrieveStopwordsSetParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
