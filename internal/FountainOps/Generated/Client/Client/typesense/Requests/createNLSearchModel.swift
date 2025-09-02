import Foundation

public struct createNLSearchModel: APIRequest {
    public typealias Body = NLSearchModelCreateSchema
    public typealias Response = Data
    public var method: String { "POST" }
    public var path: String { "/nl_search_models" }
    public var body: Body?

    public init(body: Body? = nil) {
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
