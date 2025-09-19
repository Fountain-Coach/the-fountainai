import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

#if canImport(Darwin)
setbuf(__stdoutp, nil)
setbuf(__stderrp, nil)
#elseif canImport(Glibc)
setbuf(stdout, nil)
setbuf(stderr, nil)
#endif

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

let phases = PhaseReporter(total: 6)

let dedupeResult = ServiceDeduplicator.uniquedByBinaryPath(allServices)
let services = dedupeResult.unique
if !dedupeResult.duplicates.isEmpty {
    let collapsedCount = dedupeResult.duplicates.values.flatMap { $0 }.count
    print(Console.apply("Deduplicated \(collapsedCount) service declarations sharing a binary:", .yellow))
    for (binary, duplicates) in dedupeResult.duplicates {
        let names = duplicates.map { $0.name }.joined(separator: ", ")
        print("  - \(binary): \(names)")
    }
}

let controlPlane = ControlPlane(supervisor: supervisor, services: services)

do {
    print(Console.apply("Preparing to launch \(services.count) services…", .bold))
    printServiceList(services)

    try phases.begin("Diagnostics").execute(spinnerMessage: "Checking environment") {
        try Diagnostics.run()
        return nil
    }

    try phases.begin("Build service binaries").execute {
        try Builder.build(services: services, signature: launcherSignature)
        return services.isEmpty ? "no targets" : "\(services.count) targets"
    }

    try phases.begin("Install service binaries").execute(spinnerMessage: "Copying artifacts") {
        try Installer.install(services: services)
        return nil
    }

    let manifestURL = URL(fileURLWithPath: "service-manifest.json")
    try phases.begin("Generate manifest").execute(spinnerMessage: "Hashing binaries") {
        try ManifestGenerator.generate(services: services, url: manifestURL)
        return manifestURL.path
    }

    try phases.begin("Verify manifest").execute(spinnerMessage: "Validating signatures") {
        try supervisor.verify(services: services, manifestURL: manifestURL)
        return nil
    }

    try phases.begin("Start services").execute(spinnerMessage: "Booting processes") {
        try supervisor.start(services: services)
        return "Control plane on :9090"
    }

    monitor.startMonitoring(services: services)
    Task {
        try await controlPlane.start(port: 9090)
    }
    print("\n" + Console.apply("All services running", .green))
    print("Control plane: " + Console.apply("http://127.0.0.1:9090/status", .cyan))
    printServiceSummary(services)
    print("\nPress CTRL+C to stop the launcher.")
    dispatchMain()
} catch {
    let message = "Failed to launch services: \(error)\n"
    FileHandle.standardError.write(Data(message.utf8))
    exit(1)
}

private func printServiceList(_ services: [Service]) {
    guard !services.isEmpty else {
        print("  (no services configured)")
        return
    }
    for service in services {
        if let port = service.port, let path = service.healthPath {
            print("  • \(service.name) @ \(port)\(path)")
        } else if let port = service.port {
            print("  • \(service.name) @ \(port)")
        } else {
            print("  • \(service.name)")
        }
    }
}

private func printServiceSummary(_ services: [Service]) {
    guard !services.isEmpty else { return }
    print("\n" + Console.apply("Service summary", .bold))
    let headers = ["Service", "Port", "Health", "Binary", "Restart"]
    let rows: [[String]] = services.map { service in
        let port = service.port.map(String.init) ?? "—"
        let health = service.healthPath ?? "—"
        let binary = URL(fileURLWithPath: service.binaryPath).lastPathComponent
        let restart = service.shouldRestart ? "auto" : "manual"
        return [service.name, port, health, binary, restart]
    }
    let columnWidths = headers.indices.map { index -> Int in
        let headerWidth = headers[index].count
        let rowWidth = rows.map { $0[index].count }.max() ?? 0
        return max(headerWidth, rowWidth)
    }
    let headerLine = zip(headers, columnWidths)
        .map { text, width in pad(Console.bold(text), to: width) }
        .joined(separator: "  ")
    let divider = columnWidths.map { String(repeating: "─", count: $0) }.joined(separator: "  ")
    print(headerLine)
    print(divider)
    for row in rows {
        let line = zip(row, columnWidths)
            .map { text, width in pad(text, to: width) }
            .joined(separator: "  ")
        print(line)
    }
}

private func pad(_ text: String, to width: Int) -> String {
    let padding = max(0, width - text.count)
    return text + String(repeating: " ", count: padding)
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
