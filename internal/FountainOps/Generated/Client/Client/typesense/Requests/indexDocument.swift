import Foundation

public struct indexDocumentParameters: Codable {
    public let collectionname: String
    public var action: IndexAction?
    public var dirtyValues: DirtyValues?
}

public struct indexDocument: APIRequest {
    public typealias Body = indexDocumentRequest
    public typealias Response = Data
    public var method: String { "POST" }
    public var parameters: indexDocumentParameters
    public var path: String {
        var path = "/collections/{collectionName}/documents"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{collectionName}", with: String(parameters.collectionname))
        if let value = parameters.action { query.append("action=\(value)") }
        if let value = parameters.dirtyValues { query.append("dirty_values=\(value)") }
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: indexDocumentParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
