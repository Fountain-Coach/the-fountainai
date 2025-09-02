import Foundation

public struct upsertPresetParameters: Codable {
    public let presetid: String
}

public struct upsertPreset: APIRequest {
    public typealias Body = PresetUpsertSchema
    public typealias Response = PresetSchema
    public var method: String { "PUT" }
    public var parameters: upsertPresetParameters
    public var path: String {
        var path = "/presets/{presetId}"
        var query: [String] = []
        path = path.replacingOccurrences(of: "{presetId}", with: String(parameters.presetid))
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return path
    }
    public var body: Body?

    public init(parameters: upsertPresetParameters, body: Body? = nil) {
        self.parameters = parameters
        self.body = body
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
