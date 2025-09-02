import Foundation

public struct takeSnapshotParameters: Codable {
    public let snapshotPath: String
}

public struct takeSnapshot: APIRequest {
    public typealias Body = NoBody
    public typealias Response = Data
    public var method: String { "POST" }
    public var parameters: takeSnapshotParameters
    public var path: String {
        var path = "/operations/snapshot"
        var query: [String] = []
        query.append("snapshot_path=\(parameters.snapshotPath)")
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: takeSnapshotParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
