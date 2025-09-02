import Foundation

public struct upsertAnalyticsRuleParameters: Codable {
    public let rulename: String
}

public struct upsertAnalyticsRule: APIRequest {
    public typealias Body = AnalyticsRuleUpsertSchema
    public typealias Response = AnalyticsRuleSchema
    public var method: String { "PUT" }
    public var parameters: upsertAnalyticsRuleParameters
    public var path: String {
        var path = "/analytics/rules/{ruleName}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{ruleName}", with: String(parameters.rulename))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: upsertAnalyticsRuleParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
