#!/usr/bin/env swift
import Foundation

/// Simple preflight script for FountainAI.
/// Service metadata is derived from OpenAPI specifications;
/// these specs are the authoritative source of truth for what
/// binaries the launcher manages.

struct Service {
    let name: String
    let binaryPath: String
}

func camelCaseToDash(_ input: String) -> String {
    var result = ""
    for char in input {
        if char.isUppercase {
            if !result.isEmpty { result.append("-") }
            result.append(char.lowercased())
        } else {
            result.append(char)
        }
    }
    return result
}

func loadServices() throws -> [Service] {
    let scriptPath = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
    let root = scriptPath.deletingLastPathComponent().appendingPathComponent("..").standardized
    let servicesDir = root.appendingPathComponent("services")
    let specsDir = root.appendingPathComponent("openapi/v1")
    let fm = FileManager.default
    let dirs = try fm.contentsOfDirectory(atPath: servicesDir.path).filter { !$0.hasSuffix(".md") }
    var services: [Service] = []
    for dir in dirs {
        var base = dir
        if base.hasSuffix("Server") {
            base.removeLast("Server".count)
        } else if base.hasSuffix("Service") {
            base.removeLast("Service".count)
        }
        let dashed = camelCaseToDash(base)
        let specURL = specsDir.appendingPathComponent("\(dashed).yml")
        guard fm.fileExists(atPath: specURL.path),
              let text = try? String(contentsOf: specURL) else { continue }
        var title = dashed
        if let line = text.split(separator: "\n").first(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("title:") }) {
            title = line.split(separator: ":", maxSplits: 1)[1].trimmingCharacters(in: .whitespaces)
        }
        let binaryName = dashed == "gateway" ? "fountain-gateway" : dashed
        // Prefer FOUNTAINAI_SERVICES_DIR if set; otherwise default to <repo>/dist/bin
        let binRoot = ProcessInfo.processInfo.environment["FOUNTAINAI_SERVICES_DIR"]
            ?? root.appendingPathComponent("dist/bin").path
        let binaryPath = (binRoot as NSString).appendingPathComponent(binaryName)
        services.append(Service(name: title, binaryPath: binaryPath))
    }
    return services
}

var allChecksPassed = true

func fail(_ message: String) {
    print("❌ \(message)")
    allChecksPassed = false
}

let fm = FileManager.default
let services = (try? loadServices()) ?? []

for service in services {
    if fm.isExecutableFile(atPath: service.binaryPath) {
        print("✅ \(service.name) binary found at \(service.binaryPath)")
    } else {
        fail("\(service.name) binary missing or not executable at \(service.binaryPath)")
    }
}

let requiredEnv = ["OPENAI_API_KEY", "FOUNTAINSTORE_URL", "FOUNTAINSTORE_API_KEY"]
let env = ProcessInfo.processInfo.environment
for key in requiredEnv {
    if let value = env[key], !value.isEmpty {
        print("✅ \(key) is set")
    } else {
        fail("\(key) is missing")
    }
}

if allChecksPassed {
    print("🎉 Environment looks ready for FountainAI.")
} else {
    print("⚠️ Missing requirements detected.")
}

exit(allChecksPassed ? 0 : 1)

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
