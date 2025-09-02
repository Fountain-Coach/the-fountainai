import Foundation

public struct retrieveAnalyticsRuleParameters: Codable {
    public let rulename: String
}

public struct retrieveAnalyticsRule: APIRequest {
    public typealias Body = NoBody
    public typealias Response = AnalyticsRuleSchema
    public var method: String { "GET" }
    public var parameters: retrieveAnalyticsRuleParameters
    public var path: String {
        var path = "/analytics/rules/{ruleName}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{ruleName}", with: String(parameters.rulename))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: retrieveAnalyticsRuleParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
