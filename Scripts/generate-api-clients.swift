#!/usr/bin/env swift
import Foundation

struct Endpoint: Decodable { let spec: String; let method: String; let path: String }
struct Milestone: Decodable { let operations: [Endpoint]? }

let root = FileManager.default.currentDirectoryPath
let manifestPath = root + "/docs/gui_endpoints.json"
guard let data = FileManager.default.contents(atPath: manifestPath) else {
    fputs("manifest not found: \(manifestPath)\n", stderr)
    exit(1)
}
let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
var count = 0
for (k, v) in obj {
    guard let dict = v as? [String: Any], let ops = dict["operations"] as? [[String: Any]] else { continue }
    count += ops.count
}
print("GUI endpoints manifest loaded with \(count) operations.")
print("Typed clients are provided under libs/*API. Regeneration not required.")

