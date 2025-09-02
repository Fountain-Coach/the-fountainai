import Foundation

public struct retrieveMetrics: APIRequest {
    public typealias Body = NoBody
    public typealias Response = retrieveMetricsResponse
    public var method: String { "GET" }
    public var path: String { "/metrics.json" }
    public var body: Body?

    public init(body: Body? = nil) {
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
