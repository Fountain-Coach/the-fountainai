import Foundation

/// Background repair loop that keeps trying to build and install
/// missing or failed services, then starts them once available.
final class RepairWorker {
    private let repositoryRoot: URL
    private let signature: String
    private let supervisor: Supervisor
    private var pending: [Service]
    private let backoffBase: TimeInterval = 2
    private let maxBackoff: TimeInterval = 60

    init(services: [Service], signature: String, repositoryRoot: URL, supervisor: Supervisor) {
        self.repositoryRoot = repositoryRoot
        self.signature = signature
        self.supervisor = supervisor
        self.pending = services
    }

    func start() {
        guard !pending.isEmpty else { return }
        let queue = DispatchQueue(label: "repair-worker")
        queue.async { [weak self] in
            self?.run()
        }
    }

    private func sleep(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }

    private func nextBackoff(_ attempt: Int) -> TimeInterval {
        min(maxBackoff, pow(backoffBase, Double(attempt)))
    }

    private func buildOnce(_ service: Service) -> Bool {
        do {
            try Builder.buildProduct(service: service, repositoryRoot: repositoryRoot) { event in
                switch event {
                case let .compile(module, index):
                    print(Console.apply("    [repair build] #\(index) \(module)", .cyan))
                case let .link(artifact):
                    print(Console.apply("    [repair link] \(artifact)", .magenta))
                case let .warning(message):
                    print(Console.apply("    [warn] \(message)", .yellow))
                case let .error(message):
                    print(Console.apply("    [error] \(message)", .red))
                }
            }
            return true
        } catch {
            return false
        }
    }

    private func installOnce(_ service: Service) -> Bool {
        do {
            try Installer.install(services: [service], repositoryRoot: repositoryRoot)
            return true
        } catch {
            return false
        }
    }

    private func startOnce(_ service: Service) -> Bool {
        do {
            _ = try supervisor.start(service: service)
            return true
        } catch {
            return false
        }
    }

    private func updateManifest(for services: [Service]) {
        let manifestURL = URL(fileURLWithPath: "service-manifest.json")
        try? ManifestGenerator.generate(services: services, url: manifestURL)
    }

    private func remove(_ service: Service) {
        if let idx = pending.firstIndex(where: { $0.binaryPath == service.binaryPath }) {
            pending.remove(at: idx)
        }
    }

    private func allServices() -> [Service] { pending }

    private func existingServices() -> [Service] {
        let fm = FileManager.default
        return pending.filter { fm.fileExists(atPath: $0.binaryPath) }
    }

    private func updateAndStart(_ service: Service) {
        self.updateManifest(for: [service])
        _ = self.startOnce(service)
    }

    private func printSummary() {
        if pending.isEmpty {
            print(Console.apply("Repair loop complete — all services built.", .green))
        } else {
            let names = pending.map { URL(fileURLWithPath: $0.binaryPath).lastPathComponent }.joined(separator: ", ")
            print(Console.apply("Repair loop pending: \(names)", .yellow))
        }
    }

    private func ensureLogsDir() {
        try? FileManager.default.createDirectory(at: repositoryRoot.appendingPathComponent("logs"), withIntermediateDirectories: true)
    }

    private func runInternal() {
        ensureLogsDir()
        var attempts: [String: Int] = [:]
        while !pending.isEmpty {
            for service in pending {
                let attempt = attempts[service.binaryPath, default: 0]
                print(Console.apply("Repairing \(service.name) (attempt \(attempt + 1))", .yellow))
                let built = buildOnce(service)
                if built {
                    let installed = installOnce(service)
                    if installed {
                        updateAndStart(service)
                        remove(service)
                    }
                }
                attempts[service.binaryPath] = attempt + 1
                let wait = nextBackoff(attempt + 1)
                sleep(wait)
            }
            printSummary()
        }
    }

    private func run() {
        runInternal()
    }
}
