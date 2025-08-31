import Foundation

// Load service descriptors from bundled manifest.
let services: [Service]
if let url = Bundle.module.url(forResource: "services", withExtension: "json") {
    do {
        let data = try Data(contentsOf: url)
        services = try JSONDecoder().decode([Service].self, from: data)
    } catch {
        let message = "Failed to parse services.json: \(error)\n"
        FileHandle.standardError.write(Data(message.utf8))
        exit(1)
    }
} else {
    FileHandle.standardError.write(Data("services.json not found\n".utf8))
    exit(1)
}

let launcherSignature = UUID().uuidString
let supervisor = Supervisor(launcherSignature: launcherSignature)
let monitor = HealthMonitor(supervisor: supervisor)
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
