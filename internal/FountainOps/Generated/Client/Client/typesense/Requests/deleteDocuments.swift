import Foundation

public struct deleteDocumentsParameters: Codable {
    public let collectionname: String
    public var deletedocumentsparameters: [String: String]?
}

public struct deleteDocuments: APIRequest {
    public typealias Body = NoBody
    public typealias Response = deleteDocumentsResponse
    public var method: String { "DELETE" }
    public var parameters: deleteDocumentsParameters
    public var path: String {
        var path = "/collections/{collectionName}/documents"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{collectionName}", with: String(parameters.collectionname))
        if let value = parameters.deletedocumentsparameters { query.append("deleteDocumentsParameters=\(value)") }
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: deleteDocumentsParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
