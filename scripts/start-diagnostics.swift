#!/usr/bin/env swift
import Foundation

/// Simple preflight script for FountainAI.
/// It reads the **manually maintained** `services.json` file used by the
/// launcher, verifies that each listed binary exists and is executable, and
/// checks for required environment variables.
///
/// FountainAI currently has no automatic service registry—when adding new
/// openapi servers you must update `services.json` by hand so this
/// diagnostics check and the launcher know about them.
struct Service: Decodable {
    let name: String
    let binaryPath: String
}

let scriptPath = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
let scriptDirectory = scriptPath.deletingLastPathComponent()
let servicesURL = scriptDirectory.appendingPathComponent("../FountainAiLauncher/Sources/FountainAiLauncher/services.json").standardized

var allChecksPassed = true

func fail(_ message: String) {
    print("❌ \(message)")
    allChecksPassed = false
}

let fm = FileManager.default

if fm.fileExists(atPath: servicesURL.path) {
    do {
        let data = try Data(contentsOf: servicesURL)
        let services = try JSONDecoder().decode([Service].self, from: data)
        for service in services {
            if fm.isExecutableFile(atPath: service.binaryPath) {
                print("✅ \(service.name) binary found at \(service.binaryPath)")
            } else {
                fail("\(service.name) binary missing or not executable at \(service.binaryPath)")
            }
        }
    } catch {
        fail("Failed to parse services.json: \(error)")
    }
} else {
    fail("Services configuration not found at \(servicesURL.path)")
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
