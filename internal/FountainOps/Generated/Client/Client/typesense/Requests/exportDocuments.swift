import Foundation

public struct exportDocumentsParameters: Codable {
    public let collectionname: String
    public var exportdocumentsparameters: [String: String]?
}

public struct exportDocuments: APIRequest {
    public typealias Body = NoBody
    public typealias Response = Data
    public var method: String { "GET" }
    public var parameters: exportDocumentsParameters
    public var path: String {
        var path = "/collections/{collectionName}/documents/export"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{collectionName}", with: String(parameters.collectionname))
        if let value = parameters.exportdocumentsparameters { query.append("exportDocumentsParameters=\(value)") }
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: exportDocumentsParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
