import Foundation

public struct getDocumentParameters: Codable {
    public let collectionname: String
    public let documentid: String
}

public struct getDocument: APIRequest {
    public typealias Body = NoBody
    public typealias Response = getDocumentResponse
    public var method: String { "GET" }
    public var parameters: getDocumentParameters
    public var path: String {
        var path = "/collections/{collectionName}/documents/{documentId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{collectionName}", with: String(parameters.collectionname))
        path = path.replacingOccurrences(of: "{documentId}", with: String(parameters.documentid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: getDocumentParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
