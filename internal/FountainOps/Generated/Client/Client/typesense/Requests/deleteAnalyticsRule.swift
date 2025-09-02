import Foundation

public struct deleteAnalyticsRuleParameters: Codable {
    public let rulename: String
}

public struct deleteAnalyticsRule: APIRequest {
    public typealias Body = NoBody
    public typealias Response = AnalyticsRuleDeleteResponse
    public var method: String { "DELETE" }
    public var parameters: deleteAnalyticsRuleParameters
    public var path: String {
        var path = "/analytics/rules/{ruleName}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{ruleName}", with: String(parameters.rulename))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: deleteAnalyticsRuleParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
