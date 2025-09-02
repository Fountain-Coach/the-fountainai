import Foundation

public struct getCollections: APIRequest {
    public typealias Body = NoBody
    public typealias Response = getCollectionsResponse
    public var method: String { "GET" }
    public var path: String { "/collections" }
    public var body: Body?

    public init(body: Body? = nil) {
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
