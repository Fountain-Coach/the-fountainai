import Foundation

public struct getSchemaChanges: APIRequest {
    public typealias Body = NoBody
    public typealias Response = getSchemaChangesResponse
    public var method: String { "GET" }
    public var path: String { "/operations/schema_changes" }
    public var body: Body?

    public init(body: Body? = nil) {
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
