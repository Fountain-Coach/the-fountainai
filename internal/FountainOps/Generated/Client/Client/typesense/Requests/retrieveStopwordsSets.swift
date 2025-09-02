import Foundation

public struct retrieveStopwordsSets: APIRequest {
    public typealias Body = NoBody
    public typealias Response = StopwordsSetsRetrieveAllSchema
    public var method: String { "GET" }
    public var path: String { "/stopwords" }
    public var body: Body?

    public init(body: Body? = nil) {
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
