import Foundation

public struct deletePresetParameters: Codable {
    public let presetid: String
}

public struct deletePreset: APIRequest {
    public typealias Body = NoBody
    public typealias Response = PresetDeleteSchema
    public var method: String { "DELETE" }
    public var parameters: deletePresetParameters
    public var path: String {
        var path = "/presets/{presetId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{presetId}", with: String(parameters.presetid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: deletePresetParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
