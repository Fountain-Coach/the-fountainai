import Foundation

public struct retrieveAllNLSearchModels: APIRequest {
    public typealias Body = NoBody
    public typealias Response = retrieveAllNLSearchModelsResponse
    public var method: String { "GET" }
    public var path: String { "/nl_search_models" }
    public var body: Body?

    public init(body: Body? = nil) {
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
