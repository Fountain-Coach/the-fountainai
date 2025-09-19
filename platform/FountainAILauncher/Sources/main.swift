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

enum LaunchMode {
    case launch
    case precompile
}

struct Options {
    var mode: LaunchMode = .launch
    var forceBuild = false
    var noBuild = false
}

func parseOptions() -> Options {
    var opts = Options()
    for arg in CommandLine.arguments.dropFirst() {
        switch arg {
        case "--precompile":
            opts.mode = .precompile
        case "--force-build":
            opts.forceBuild = true
        case "--no-build":
            opts.noBuild = true
        default:
            break
        }
    }
    return opts
}

let options = parseOptions()
// monitor will be created after supervisor is initialized

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

    var servicesToLaunch = uniqueServices

    func installedArtifactsValid(for services: [Service], manifestURL: URL) -> Bool {
        let allBinariesExist = services.allSatisfy { FileManager.default.fileExists(atPath: $0.binaryPath) }
        guard allBinariesExist, FileManager.default.fileExists(atPath: manifestURL.path) else { return false }
        do {
            try Supervisor(launcherSignature: "").verify(services: services, manifestURL: manifestURL)
            return true
        } catch {
            return false
        }
    }

    if options.mode != .precompile {
        let preflightPhase = phases.begin("Preflight checks")
        var preflightOutcome = PreflightOutcome.ok
        let preflightSpinner = Spinner(message: "Validating prerequisites")
        preflightSpinner.start()
        do {
            let note = try Preflight.run()
            preflightOutcome = note
            preflightSpinner.stop(success: true)
            preflightPhase.succeed(note: note.note)
        } catch {
            preflightSpinner.stop(success: false)
            preflightPhase.fail(with: error)
            throw error
        }

        if preflightOutcome.needsLocalStore, let override = preflightOutcome.localStoreURL {
            setenv("FOUNTAINSTORE_URL", override.absoluteString, 1)
            if let p = preflightOutcome.localStorePort { setenv("FOUNTAINSTORE_PORT", String(p), 1) }
            if (ProcessInfo.processInfo.environment["FOUNTAINSTORE_API_KEY"] ?? "").isEmpty {
                setenv("FOUNTAINSTORE_API_KEY", "dev", 1)
            }
            print(Console.apply("Routing FOUNTAINSTORE_URL to \(override.absoluteString) for embedded FountainStore.", .yellow))
            if let index = servicesToLaunch.firstIndex(where: { URL(fileURLWithPath: $0.binaryPath).lastPathComponent == "persist" }) {
                var storeService = servicesToLaunch.remove(at: index)
                if let newPort = preflightOutcome.localStorePort {
                    storeService = Service(
                        name: storeService.name,
                        binaryPath: storeService.binaryPath,
                        arguments: storeService.arguments,
                        port: newPort,
                        healthPath: storeService.healthPath,
                        shouldRestart: storeService.shouldRestart
                    )
                }
                servicesToLaunch.insert(storeService, at: 0)
            } else {
                print(Console.apply("Warning: could not locate local FountainStore service definition.", .red))
            }
        }
    }

    print(Console.apply("Preparing to launch \(servicesToLaunch.count) services…", .bold))
    printServiceList(servicesToLaunch)

    func loadSourceEmbeddedSignature(layout: RepositoryLayout) -> String? {
        let path = layout.root.appendingPathComponent("libs/LauncherSignature/Signature.swift").path
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        // Parse the Swift source line: public let embeddedLauncherSignature = "..."
        if let range = content.range(of: "embeddedLauncherSignature = \"") {
            let rest = content[range.upperBound...]
            if let end = rest.firstIndex(of: "\"") {
                return String(rest[..<end])
            }
        }
        return nil
    }

    // Establish or reuse a launcher signature for binary validation
    let selectedSignature: String = {
        if let stored = SignatureStore.load(from: layout) {
            return stored
        }
        if let srcSig = loadSourceEmbeddedSignature(layout: layout) {
            return srcSig
        }
        let fresh = UUID().uuidString
        try? SignatureStore.save(fresh, layout: layout)
        return fresh
    }()
    // Seed defaults for services that require envs to start locally
    var baseEnv = ProcessInfo.processInfo.environment
    if baseEnv["SEC_SENTINEL_URL"] == nil { baseEnv["SEC_SENTINEL_URL"] = "http://127.0.0.1:0" }
    if baseEnv["SEC_SENTINEL_API_KEY"] == nil { baseEnv["SEC_SENTINEL_API_KEY"] = "dev" }
    let supervisor = Supervisor(environment: baseEnv, launcherSignature: selectedSignature)
    let monitor = HealthMonitor(supervisor: supervisor)
    let controlPlane = ControlPlane(supervisor: supervisor, services: servicesToLaunch)

    if options.mode != .precompile {
        try phases.begin("Diagnostics").execute(spinnerMessage: "Checking environment") {
            do {
                try Diagnostics.run()
                return nil
            } catch {
                print(Console.apply("Diagnostics warnings: \(error)", .yellow))
                return "warnings"
            }
        }
    }

    let manifestURL = URL(fileURLWithPath: "service-manifest.json")

    func buildAndInstall() throws -> (built: [Service], failed: [Service]) {
        let hb = Heartbeat(message: "[hb] building service binaries…", interval: 1)
        hb.start()
        var built: [Service] = []
        var failed: [Service] = []

        var result: Builder.Summary = .init(built: [], failed: [])
        try phases.begin("Build service binaries").execute {
            result = Builder.buildAll(services: servicesToLaunch, signature: selectedSignature, repositoryRoot: layout.root) { event in
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
            return "built \(result.built.count), failed \(result.failed.count)"
        }
        built = result.built
        failed = result.failed.map { $0.0 }

        try phases.begin("Install service binaries").execute(spinnerMessage: "Copying artifacts") {
            try Installer.install(services: built, repositoryRoot: layout.root)
            return nil
        }

        try phases.begin("Generate manifest").execute(spinnerMessage: "Hashing binaries") {
            try ManifestGenerator.generate(services: built, url: manifestURL)
            return manifestURL.path
        }

        try SignatureStore.save(selectedSignature, layout: layout)

        try phases.begin("Verify manifest").execute(spinnerMessage: "Validating signatures") {
            try supervisor.verify(services: built, manifestURL: manifestURL)
            return nil
        }
        hb.stop()
        return (built, failed)
    }

    // Precompile-only mode: build and install artifacts, then exit.
    if options.mode == .precompile {
        _ = try buildAndInstall()
        print(Console.apply("Precompile complete. Artifacts installed to dist/bin", .green))
        exit(0)
    }

    // Decide whether to build or reuse precompiled artifacts
    var shouldBuild = !options.noBuild
    if !options.forceBuild {
        let valid = installedArtifactsValid(for: servicesToLaunch, manifestURL: manifestURL)
        if valid { shouldBuild = false }
    } else {
        shouldBuild = true
    }

    var builtServices: [Service] = []
    var failedServices: [Service] = []
    if shouldBuild {
        let result = try buildAndInstall()
        builtServices = result.built
        failedServices = result.failed
    } else {
        print(Console.apply("Using precompiled artifacts (skipping build)", .green))
        // Verify and collect ready services
        var ready: [Service] = []
        for svc in servicesToLaunch {
            do {
                try supervisor.verify(services: [svc], manifestURL: manifestURL)
                ready.append(svc)
            } catch {
                failedServices.append(svc)
            }
        }
        builtServices = ready
        if !FileManager.default.fileExists(atPath: manifestURL.path) {
            try phases.begin("Generate manifest").execute(spinnerMessage: "Hashing binaries") {
                try ManifestGenerator.generate(services: builtServices, url: manifestURL)
                return manifestURL.path
            }
        }
    }

    // Start ready services first
    try phases.begin("Start services").execute(spinnerMessage: "Booting processes") {
        try supervisor.start(services: builtServices)
        return "Control plane on :9090"
    }

    Thread.sleep(forTimeInterval: 1)
    let healthSnapshot = HealthMonitor.initialCheck(services: builtServices)

    monitor.startMonitoring(services: builtServices)
    // Start self-correction by scanning logs for known issues.
    let corrector = SelfCorrector(supervisor: supervisor)
    corrector.start(for: builtServices)
    Task {
        try await controlPlane.start(port: 9090)
    }
    if builtServices.isEmpty {
        print("\n" + Console.apply("No services started yet — repair loop active", .yellow))
    } else {
        print("\n" + Console.apply("All services running", .green))
    }
    print("Control plane: " + Console.apply("http://127.0.0.1:9090/status", .cyan))
    printServiceSummary(builtServices, health: healthSnapshot)
    printHealthIssues(healthSnapshot)
    if !failedServices.isEmpty {
        let names = failedServices.map { $0.name }.joined(separator: ", ")
        print(Console.apply("Background repair will attempt to build: \(names)", .yellow))
        let worker = RepairWorker(services: failedServices, signature: selectedSignature, repositoryRoot: layout.root, supervisor: supervisor)
        worker.start()
    }
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
