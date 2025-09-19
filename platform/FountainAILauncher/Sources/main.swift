import Foundation

// Discover services from OpenAPI gateway specifications.
let allServices: [Service]
do {
    allServices = try OpenAPIServiceLoader.loadServices()
} catch {
    let message = "Failed to load services: \(error)\n"
    FileHandle.standardError.write(Data(message.utf8))
    exit(1)
}

let launcherSignature = UUID().uuidString
let supervisor = Supervisor(launcherSignature: launcherSignature)
let monitor = HealthMonitor(supervisor: supervisor)

let dedupeResult = ServiceDeduplicator.uniquedByBinaryPath(allServices)
let services = dedupeResult.unique
if !dedupeResult.duplicates.isEmpty {
    let collapsedCount = dedupeResult.duplicates.values.flatMap { $0 }.count
    print("Deduplicated \(collapsedCount) service declarations sharing the same binary path:")
    for (binary, duplicates) in dedupeResult.duplicates {
        let names = duplicates.map { $0.name }.joined(separator: ", ")
        print("  - \(binary): \(names)")
    }
}

print("Launching \(services.count) services:")
for service in services {
    if let port = service.port, let path = service.healthPath {
        print("  - \(service.name) @ \(port)\(path)")
    } else {
        print("  - \(service.name)")
    }
}

let controlPlane = ControlPlane(supervisor: supervisor, services: services)

do {
    try Diagnostics.run()
    try Builder.build(services: services, signature: launcherSignature)
    try Installer.install(services: services)
    let manifestURL = URL(fileURLWithPath: "service-manifest.json")
    try ManifestGenerator.generate(services: services, url: manifestURL)
    try supervisor.verify(services: services, manifestURL: manifestURL)
    try supervisor.start(services: services)
    monitor.startMonitoring(services: services)
    Task {
        try await controlPlane.start(port: 9090)
    }
    dispatchMain()
} catch {
    let message = "Failed to launch services: \(error)\n"
    FileHandle.standardError.write(Data(message.utf8))
    exit(1)
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
