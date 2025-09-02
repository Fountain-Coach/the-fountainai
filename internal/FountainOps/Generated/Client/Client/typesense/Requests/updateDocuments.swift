import Foundation

public struct updateDocumentsParameters: Codable {
    public let collectionname: String
    public var updatedocumentsparameters: [String: String]?
}

public struct updateDocuments: APIRequest {
    public typealias Body = updateDocumentsRequest
    public typealias Response = updateDocumentsResponse
    public var method: String { "PATCH" }
    public var parameters: updateDocumentsParameters
    public var path: String {
        var path = "/collections/{collectionName}/documents"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{collectionName}", with: String(parameters.collectionname))
        if let value = parameters.updatedocumentsparameters { query.append("updateDocumentsParameters=\(value)") }
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: updateDocumentsParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
