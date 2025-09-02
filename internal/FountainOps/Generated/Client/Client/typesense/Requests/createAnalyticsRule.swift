import Foundation

public struct createAnalyticsRule: APIRequest {
    public typealias Body = AnalyticsRuleSchema
    public typealias Response = Data
    public var method: String { "POST" }
    public var path: String { "/analytics/rules" }
    public var body: Body?

    public init(body: Body? = nil) {
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
