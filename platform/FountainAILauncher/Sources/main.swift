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

let launcherSignature = UUID().uuidString
let supervisor = Supervisor(launcherSignature: launcherSignature)
let monitor = HealthMonitor(supervisor: supervisor)

let phases = PhaseReporter(total: 7)

do {
    let layout = try RepositoryLayout.detect()
    let services = try loadServices(from: layout)

    let dedupeResult = ServiceDeduplicator.uniquedByBinaryPath(services)
    let uniqueServices = dedupeResult.unique
    if !dedupeResult.duplicates.isEmpty {
        let collapsedCount = dedupeResult.duplicates.values.flatMap { $0 }.count
        print(Console.apply("Deduplicated \(collapsedCount) service declarations sharing a binary:", .yellow))
        for (binary, duplicates) in dedupeResult.duplicates {
            let names = duplicates.map { $0.name }.joined(separator: ", ")
            print("  - \(binary): \(names)")
        }
    }

    let controlPlane = ControlPlane(supervisor: supervisor, services: uniqueServices)

    print(Console.apply("Preparing to launch \(services.count) services…", .bold))
    printServiceList(uniqueServices)

    try phases.begin("Preflight checks").execute(spinnerMessage: "Validating prerequisites") {
        return try Preflight.run()
    }

    try phases.begin("Diagnostics").execute(spinnerMessage: "Checking environment") {
        try Diagnostics.run()
        return nil
    }

    try phases.begin("Build service binaries").execute {
        try Builder.build(services: uniqueServices, signature: launcherSignature, repositoryRoot: layout.root) { event in
            switch event {
            case let .compile(module, index):
                print(Console.apply("    [build] #\(index) \(module)", .cyan))
            case let .link(artifact):
                print(Console.apply("    [link] \(artifact)", .magenta))
            case let .warning(message):
                print(Console.apply("    [warn] \(message)", .yellow))
            case let .error(message):
                print(Console.apply("    [error] \(message)", .red))
            }
        }
        return uniqueServices.isEmpty ? "no targets" : "\(uniqueServices.count) targets"
    }

    try phases.begin("Install service binaries").execute(spinnerMessage: "Copying artifacts") {
        try Installer.install(services: uniqueServices, repositoryRoot: layout.root)
        return nil
    }

    let manifestURL = URL(fileURLWithPath: "service-manifest.json")
    try phases.begin("Generate manifest").execute(spinnerMessage: "Hashing binaries") {
        try ManifestGenerator.generate(services: uniqueServices, url: manifestURL)
        return manifestURL.path
    }

    try phases.begin("Verify manifest").execute(spinnerMessage: "Validating signatures") {
        try supervisor.verify(services: uniqueServices, manifestURL: manifestURL)
        return nil
    }

    try phases.begin("Start services").execute(spinnerMessage: "Booting processes") {
        try supervisor.start(services: uniqueServices)
        return "Control plane on :9090"
    }

    Thread.sleep(forTimeInterval: 1)
    let healthSnapshot = HealthMonitor.initialCheck(services: uniqueServices)

    monitor.startMonitoring(services: uniqueServices)
    Task {
        try await controlPlane.start(port: 9090)
    }
    print("\n" + Console.apply("All services running", .green))
    print("Control plane: " + Console.apply("http://127.0.0.1:9090/status", .cyan))
    printServiceSummary(uniqueServices, health: healthSnapshot)
    printHealthIssues(healthSnapshot)
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

private func printServiceSummary(_ services: [Service], health: [HealthMonitor.HealthCheckResult]) {
    guard !services.isEmpty else { return }
    let healthLookup = Dictionary(uniqueKeysWithValues: health.map { ($0.service.name, $0) })
    print("\n" + Console.apply("Service summary", .bold))
    let headers = ["Service", "Port", "Health Path", "Status", "Binary", "Restart"]
    let rows: [[String]] = services.map { service in
        let port = service.port.map(String.init) ?? "—"
        let healthPath = service.healthPath ?? "—"
        let binary = URL(fileURLWithPath: service.binaryPath).lastPathComponent
        let restart = service.shouldRestart ? "auto" : "manual"
        let status: String
        if let snapshot = healthLookup[service.name] {
            status = snapshot.healthy ? Console.apply("healthy", .green) : Console.apply("unhealthy", .red)
        } else {
            status = Console.apply("pending", .yellow)
        }
        return [service.name, port, healthPath, status, binary, restart]
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

private func loadServices(from layout: RepositoryLayout) throws -> [Service] {
    try OpenAPIServiceLoader.loadServices(root: layout.openAPIRoot, servicesDirectory: layout.servicesDirectory)
}

private func printHealthIssues(_ statuses: [HealthMonitor.HealthCheckResult]) {
    let failing = statuses.filter { !$0.healthy }
    guard !failing.isEmpty else {
        print(Console.apply("All services responded healthy.", .green))
        return
    }
    print(Console.apply("Services reporting unhealthy status:", .red))
    for status in failing {
        let detail = status.detail ?? "no response"
        print("  - \(status.service.name): \(detail)")
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
