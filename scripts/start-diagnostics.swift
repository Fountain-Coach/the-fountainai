#!/usr/bin/env swift
import Foundation

/// Simple preflight script for FountainAI.
/// It scans the OpenAPI specifications for gateway services, verifies that
/// each referenced binary exists and is executable, and checks for required
/// environment variables.

struct Service {
    let name: String
    let binaryPath: String
}

let scriptPath = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
let scriptDirectory = scriptPath.deletingLastPathComponent()
let repoRoot = scriptDirectory.appendingPathComponent("..").standardized

var allChecksPassed = true

func fail(_ message: String) {
    print("❌ \(message)")
    allChecksPassed = false
}

let fm = FileManager.default

func discoverServices() -> [Service] {
    let openapiURL = repoRoot.appendingPathComponent("openapi")
    let servicesDir = ProcessInfo.processInfo.environment["FOUNTAINAI_SERVICES_DIR"] ?? "/usr/local/bin"
    var services: [Service] = []
    guard let versions = try? fm.contentsOfDirectory(at: openapiURL, includingPropertiesForKeys: nil) else {
        fail("OpenAPI directory not found at \(openapiURL.path)")
        return []
    }
    for version in versions where version.lastPathComponent.hasPrefix("v") {
        if let specs = try? fm.contentsOfDirectory(at: version, includingPropertiesForKeys: nil) {
            for spec in specs where spec.lastPathComponent.hasSuffix("-gateway.yml") {
                if let text = try? String(contentsOf: spec) {
                    let name = parseField("title", in: text) ?? spec.deletingPathExtension().lastPathComponent
                    let binary = parseField("x-fountain.binary", in: text) ?? spec.deletingPathExtension().lastPathComponent
                    let binaryPath = (servicesDir as NSString).appendingPathComponent(binary)
                    services.append(Service(name: name, binaryPath: binaryPath))
                }
            }
        }
    }
    return services
}

func parseField(_ key: String, in text: String) -> String? {
    for line in text.components(separatedBy: "\n") {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("\(key):") {
            return trimmed.split(separator: ":", maxSplits: 1).last?.trimmingCharacters(in: .whitespaces)
        }
    }
    return nil
}

let services = discoverServices()
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
