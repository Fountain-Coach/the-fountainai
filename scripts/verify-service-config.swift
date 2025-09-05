#!/usr/bin/env swift
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let fm = FileManager.default

let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])!

var offenders: [String] = []

let forbiddenFileName = "services.json"
let jsonPattern = try! NSRegularExpression(pattern: #"(?s)\"name\"\s*:\s*\"[^\"]+\".*\"port\"\s*:\s*\d{2,5}"#)
let swiftPattern = try! NSRegularExpression(pattern: #"(?s)name:\s*\"[^\"]+\".*port:\s*\d{2,5}"#)

while let url = enumerator.nextObject() as? URL {
    let path = url.path
    if path.contains("/.git/") { continue }
    if path.contains("/Tests/") { continue }
    if url.lastPathComponent == forbiddenFileName {
        offenders.append(path)
        continue
    }
    if let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        if jsonPattern.firstMatch(in: text, options: [], range: range) != nil ||
           swiftPattern.firstMatch(in: text, options: [], range: range) != nil {
            offenders.append(path)
        }
    }
}

if !offenders.isEmpty {
    fputs("Disallowed service configuration found:\n", stderr)
    for o in offenders {
        fputs("- \(o)\n", stderr)
    }
    exit(1)
}

print("Service configuration verified: no forbidden files found.")

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
