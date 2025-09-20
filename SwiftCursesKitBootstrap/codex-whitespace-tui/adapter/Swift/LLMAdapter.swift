// LLMAdapter.swift
// Minimal adapter to call LLM UI generator and enforce policies.

import Foundation

struct TerminalInfo: Codable { let rows: Int; let cols: Int }
struct ContextContent: Codable { let type: String; let data: [String:AnyCodable] }
struct Context: Codable { let terminal: TerminalInfo; let active_content: ContextContent }
enum Role: String, Codable { case designerAssistant = "designer-assistant" }
enum Task: String, Codable { case layoutSuggestion = "layout_suggestion" }

struct LLMRequest: Codable {
    let request_id: String
    let role: Role
    let task: Task
    let context: Context
    let instructions: String
}

struct Component: Codable {
    let id: String
    let type: String
    let x: Int
    let y: Int
    let width: Int
    let height: Int
    let props: [String:AnyCodable]?
}

struct LLMResponse: Codable {
    let request_id: String?
    let status: String
    let reason: String?
    let components: [Component]?
    let explanation: String?
}

public final class LLMAdapter {
    let baseURL: URL
    let session = URLSession(configuration: .default)

    public init(baseURL: URL) { self.baseURL = baseURL }

    public func generateLayout(terminalRows: Int, terminalCols: Int, contentType: String, contentData: [String:AnyCodable]) async throws -> [Component] {
        let ctx = Context(
            terminal: TerminalInfo(rows: terminalRows, cols: terminalCols),
            active_content: ContextContent(type: contentType, data: contentData)
        )
        let req = LLMRequest(
            request_id: UUID().uuidString,
            role: .designerAssistant,
            task: .layoutSuggestion,
            context: ctx,
            instructions: "Use whitespace-forward style; follow palette/states; rail only if cols>=120"
        )
        let requestURL = baseURL.appendingPathComponent("/v1/ui/generate")
        var urlReq = URLRequest(url: requestURL)
        urlReq.httpMethod = "POST"
        urlReq.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlReq.httpBody = try JSONEncoder().encode(req)

        let (data, resp) = try await session.data(for: urlReq)
        guard (resp as? HTTPURLResponse)?.statusCode ?? 500 < 300 else {
            throw NSError(domain: "LLMAdapter", code: 1, userInfo: [NSLocalizedDescriptionKey: "HTTP error"])
        }
        let parsed = try JSONDecoder().decode(LLMResponse.self, from: data)
        guard parsed.status == "ok", let comps = parsed.components else {
            return fallbackLayout(rows: terminalRows, cols: terminalCols, reason: parsed.reason)
        }
        return enforcePolicy(comps, rows: terminalRows, cols: terminalCols)
    }

    // Clamp sizes and enforce color/rail policy (example: only structural checks here)
    private func enforcePolicy(_ comps: [Component], rows: Int, cols: Int) -> [Component] {
        let maxCols = cols
        let maxRows = rows
        let railAllowed = cols >= 120
        return comps.compactMap { c in
            var cx = max(0, min(c.x, maxCols-1))
            var cy = max(0, min(c.y, maxRows-1))
            var cw = max(10, min(c.width, maxCols - cx))
            var ch = max(1, min(c.height, maxRows - cy))
            // Example rail filter: drop too-wide inspector if rail not allowed
            if c.type == "Inspector" && !railAllowed { return nil }
            return Component(id: c.id, type: c.type, x: cx, y: cy, width: cw, height: ch, props: c.props)
        }
    }

    private func fallbackLayout(rows: Int, cols: Int, reason: String?) -> [Component] {
        let width = min(76, cols-4)
        return [
            Component(id: "heading", type: "Heading", x: 2, y: 1, width: width, height: 1,
                      props: ["text": AnyCodable("Fallback layout"), "style": AnyCodable(["bold": true, "color_pair": 2])]),
            Component(id: "card_info", type: "Card", x: 2, y: 3, width: width, height: 6,
                      props: ["title": AnyCodable("Info"),
                              "items": AnyCodable([["label":"status","value":"fallback"],["label":"reason","value": reason ?? "-"]])])
        ]
    }
}

// Minimal AnyCodable for quick prototyping

public struct AnyCodable: Codable {
    public let value: Any
    public init(_ value: Any) { self.value = value }
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Bool.self) { value = v; return }
        if let v = try? c.decode(Int.self) { value = v; return }
        if let v = try? c.decode(Double.self) { value = v; return }
        if let v = try? c.decode(String.self) { value = v; return }
        if let v = try? c.decode([String:AnyCodable].self) { value = v; return }
        if let v = try? c.decode([AnyCodable].self) { value = v; return }
        throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported type")
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let v as Bool: try c.encode(v)
        case let v as Int: try c.encode(v)
        case let v as Double: try c.encode(v)
        case let v as String: try c.encode(v)
        case let v as [String:AnyCodable]: try c.encode(v)
        case let v as [AnyCodable]: try c.encode(v)
        default:
            let ctx = EncodingError.Context(codingPath: c.codingPath, debugDescription: "Unsupported type")
            throw EncodingError.invalidValue(value, ctx)
        }
    }
}
