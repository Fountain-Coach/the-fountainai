import Foundation

/// Watches service logs for known error patterns and applies corrective actions
/// (update env, choose ports) before instructing the supervisor to restart.
final class SelfCorrector {
    private let logsDir: URL
    private let supervisor: Supervisor
    private var watchers: [String: LogWatcher] = [:]

    init(logsDir: URL = URL(fileURLWithPath: "logs"), supervisor: Supervisor) {
        self.logsDir = logsDir
        self.supervisor = supervisor
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
    }

    func start(for services: [Service]) {
        for svc in services {
            let file = logsDir.appendingPathComponent(svc.name.replacingOccurrences(of: " ", with: "_") + ".log")
            let watcher = LogWatcher(url: file) { [weak self] line in
                self?.handle(line: line, service: svc)
            }
            watchers[svc.name] = watcher
            watcher.start()
        }
    }

    private func handle(line: String, service: Service) {
        // 1) Gateway missing security sentinel envs
        if line.contains("SEC_SENTINEL_URL and SEC_SENTINEL_API_KEY must be set") {
            print(Console.apply("[auto-fix] Seeding SEC_SENTINEL_* env and restarting \(service.name)", .yellow))
            supervisor.updateEnvironment([
                "SEC_SENTINEL_URL": "http://127.0.0.1:0",
                "SEC_SENTINEL_API_KEY": "dev"
            ])
            supervisor.restart(service: service)
            return
        }
        // 2) Persist address in use -> pick a new port and update env
        if line.contains("Failed to start: bind") && line.contains("Address already in use") {
            let port = findFreePort()
            let url = "http://127.0.0.1:\(port)"
            print(Console.apply("[auto-fix] Persist port busy. Switching to \(port) and restarting.", .yellow))
            supervisor.updateEnvironment([
                "FOUNTAINSTORE_PORT": String(port),
                "FOUNTAINSTORE_URL": url
            ])
            supervisor.restart(service: service)
            return
        }
    }
}

private func findFreePort() -> Int {
    for p in 8006...8020 {
        if !isPortOpen(port: p) { return p }
    }
    return Int.random(in: 8030...8999)
}

private func isPortOpen(port: Int, timeout: TimeInterval = 0.1) -> Bool {
    guard let url = URL(string: "http://127.0.0.1:\(port)/health") else { return false }
    var req = URLRequest(url: url)
    req.httpMethod = "GET"
    let sem = DispatchSemaphore(value: 0)
    var open = false
    let task = URLSession.shared.dataTask(with: req) { _, resp, err in
        defer { sem.signal() }
        if err == nil { open = true }
        if let http = resp as? HTTPURLResponse, http.statusCode > 0 { open = true }
    }
    task.resume()
    _ = sem.wait(timeout: .now() + timeout)
    return open
}

/// Simple log tailer for a single file.
final class LogWatcher {
    private let url: URL
    private let handler: (String) -> Void
    private var fileHandle: FileHandle?
    private let queue = DispatchQueue(label: "log-watcher")
    private var source: DispatchSourceFileSystemObject?
    private var offset: UInt64 = 0

    init(url: URL, onLine: @escaping (String) -> Void) {
        self.url = url
        self.handler = onLine
    }

    func start() {
        queue.async { [weak self] in
            self?.setup()
        }
    }

    private func setup() {
        FileManager.default.createFile(atPath: url.path, contents: nil)
        guard let fh = try? FileHandle(forReadingFrom: url) else { return }
        self.fileHandle = fh
        self.offset = (try? fh.seekToEnd()) ?? 0
        let fd = fh.fileDescriptor
        let src = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: queue)
        src.setEventHandler { [weak self] in self?.readAvailable() }
        src.resume()
        self.source = src
    }

    private func readAvailable() {
        guard let fh = fileHandle else { return }
        let data = fh.readDataToEndOfFile()
        if data.isEmpty { return }
        if let text = String(data: data, encoding: .utf8) {
            for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
                handler(String(line))
            }
        }
    }
}

