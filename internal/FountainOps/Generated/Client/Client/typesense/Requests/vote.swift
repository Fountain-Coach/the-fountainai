import Foundation

public struct vote: APIRequest {
    public typealias Body = NoBody
    public typealias Response = SuccessStatus
    public var method: String { "POST" }
    public var path: String { "/operations/vote" }
    public var body: Body?

    public init(body: Body? = nil) {
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
