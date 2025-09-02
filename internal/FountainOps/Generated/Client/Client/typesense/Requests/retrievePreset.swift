import Foundation

public struct retrievePresetParameters: Codable {
    public let presetid: String
}

public struct retrievePreset: APIRequest {
    public typealias Body = NoBody
    public typealias Response = PresetSchema
    public var method: String { "GET" }
    public var parameters: retrievePresetParameters
    public var path: String {
        var path = "/presets/{presetId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{presetId}", with: String(parameters.presetid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: retrievePresetParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
