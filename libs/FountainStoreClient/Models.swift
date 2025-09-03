import Foundation

public struct CorpusCreateRequest: Codable, Sendable {
    public let corpusId: String
    public init(corpusId: String) { self.corpusId = corpusId }
}
public struct CorpusResponse: Codable, Sendable {
    public let corpusId: String; public let message: String
    public init(corpusId: String, message: String) { self.corpusId = corpusId; self.message = message }
}

public struct Baseline: Codable, Sendable {
    public let corpusId: String
    public let baselineId: String
    public let content: String
    public let ts: Double

    public init(corpusId: String, baselineId: String, content: String, ts: Double = Date().timeIntervalSince1970) {
        self.corpusId = corpusId
        self.baselineId = baselineId
        self.content = content
        self.ts = ts
    }
}

public struct Reflection: Codable, Sendable {
    public let corpusId: String
    public let reflectionId: String
    public let question: String
    public let content: String
    public let ts: Double

    public init(corpusId: String, reflectionId: String, question: String, content: String, ts: Double = Date().timeIntervalSince1970) {
        self.corpusId = corpusId
        self.reflectionId = reflectionId
        self.question = question
        self.content = content
        self.ts = ts
    }
}

public struct Drift: Codable, Sendable {
    public let corpusId: String
    public let driftId: String
    public let content: String
    public let ts: Double

    public init(corpusId: String, driftId: String, content: String, ts: Double = Date().timeIntervalSince1970) {
        self.corpusId = corpusId
        self.driftId = driftId
        self.content = content
        self.ts = ts
    }
}

public struct Patterns: Codable, Sendable {
    public let corpusId: String
    public let patternsId: String
    public let content: String
    public let ts: Double

    public init(corpusId: String, patternsId: String, content: String, ts: Double = Date().timeIntervalSince1970) {
        self.corpusId = corpusId
        self.patternsId = patternsId
        self.content = content
        self.ts = ts
    }
}

public struct Role: Codable, Sendable {
    public let corpusId: String
    public let name: String
    public let prompt: String

    public init(corpusId: String, name: String, prompt: String) {
        self.corpusId = corpusId
        self.name = name
        self.prompt = prompt
    }
}

public struct FunctionModel: Codable, Sendable {
    public let corpusId: String
    public let functionId: String
    public let name: String
    public let description: String
    public let httpMethod: String
    public let httpPath: String

    public init(corpusId: String, functionId: String, name: String, description: String, httpMethod: String, httpPath: String) {
        self.corpusId = corpusId
        self.functionId = functionId
        self.name = name
        self.description = description
        self.httpMethod = httpMethod
        self.httpPath = httpPath
    }
}

public struct SuccessResponse: Codable, Sendable { public let message: String }

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
