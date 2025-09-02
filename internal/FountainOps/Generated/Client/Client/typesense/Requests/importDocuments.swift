import Foundation

public struct importDocumentsParameters: Codable {
    public let collectionname: String
    public var importdocumentsparameters: [String: String]?
}

public struct importDocuments: APIRequest {
    public typealias Body = NoBody
    public typealias Response = Data
    public var method: String { "POST" }
    public var parameters: importDocumentsParameters
    public var path: String {
        var path = "/collections/{collectionName}/documents/import"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{collectionName}", with: String(parameters.collectionname))
        if let value = parameters.importdocumentsparameters { query.append("importDocumentsParameters=\(value)") }
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: importDocumentsParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
