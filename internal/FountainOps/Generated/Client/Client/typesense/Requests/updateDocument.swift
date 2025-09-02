import Foundation

public struct updateDocumentParameters: Codable {
    public let collectionname: String
    public let documentid: String
    public var dirtyValues: DirtyValues?
}

public struct updateDocument: APIRequest {
    public typealias Body = updateDocumentRequest
    public typealias Response = updateDocumentResponse
    public var method: String { "PATCH" }
    public var parameters: updateDocumentParameters
    public var path: String {
        var path = "/collections/{collectionName}/documents/{documentId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{collectionName}", with: String(parameters.collectionname))
        path = path.replacingOccurrences(of: "{documentId}", with: String(parameters.documentid))
        if let value = parameters.dirtyValues { query.append("dirty_values=\(value)") }
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: updateDocumentParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
