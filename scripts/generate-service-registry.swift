import Foundation

struct Template {
    let name: String
    let binary: String
    let port: Int
    let healthPath: String
    let shouldRestart: Bool
}

struct Service: Codable {
    let name: String
    let binaryPath: String
    let port: Int
    let healthPath: String
    let shouldRestart: Bool
}

let templates: [Template] = [
    Template(name: "Baseline Awareness", binary: "baseline-awareness", port: 8001, healthPath: "/metrics", shouldRestart: true),
    Template(name: "Bootstrap", binary: "bootstrap", port: 8002, healthPath: "/metrics", shouldRestart: true),
    Template(name: "Planner", binary: "planner", port: 8003, healthPath: "/metrics", shouldRestart: true),
    Template(name: "Function Caller", binary: "function-caller", port: 8004, healthPath: "/metrics", shouldRestart: true),
    Template(name: "Persist", binary: "persist", port: 8005, healthPath: "/metrics", shouldRestart: true),
    Template(name: "LLM Gateway", binary: "llm-gateway", port: 8006, healthPath: "/metrics", shouldRestart: true),
    Template(name: "Semantic Browser", binary: "semantic-browser", port: 8007, healthPath: "/metrics", shouldRestart: true),
    Template(name: "Gateway", binary: "fountain-gateway", port: 8010, healthPath: "/metrics", shouldRestart: true),
    Template(name: "Tools Factory", binary: "tools-factory", port: 8011, healthPath: "/metrics", shouldRestart: true)
]

let servicesDir = ProcessInfo.processInfo.environment["FOUNTAINAI_SERVICES_DIR"] ?? "/usr/local/bin"
var services: [Service] = []

for t in templates {
    let path = (servicesDir as NSString).appendingPathComponent(t.binary)
    if !FileManager.default.isExecutableFile(atPath: path) {
        fputs("Warning: \(path) not found or not executable\n", stderr)
    }
    services.append(Service(name: t.name, binaryPath: path, port: t.port, healthPath: t.healthPath, shouldRestart: t.shouldRestart))
}

do {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    let data = try encoder.encode(services)
    let outputURL = URL(fileURLWithPath: "FountainAiLauncher/Sources/FountainAiLauncher/services.json")
    try data.write(to: outputURL)
    print("Wrote services.json with \(services.count) entries to \(outputURL.path)")
} catch {
    fputs("Failed to write services.json: \(error)\n", stderr)
    exit(1)
}
