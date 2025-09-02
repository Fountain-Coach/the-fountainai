import Foundation

public struct retrieveAllPresets: APIRequest {
    public typealias Body = NoBody
    public typealias Response = PresetsRetrieveSchema
    public var method: String { "GET" }
    public var path: String { "/presets" }
    public var body: Body?

    public init(body: Body? = nil) {
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
