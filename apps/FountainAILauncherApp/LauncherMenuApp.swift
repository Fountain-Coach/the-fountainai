import SwiftUI
import Foundation
import AppKit

#if os(macOS)
@main
struct LauncherMenuApp: App {
    @StateObject private var controller = LauncherController()

    var body: some Scene {
        MenuBarExtra("FountainAI", systemImage: "gearshape.2") {
            Group {
                if controller.launcherRunning {
                    Button("Stop Launcher") { controller.stopLauncher() }
                    Button("Open Dashboard") { controller.openDashboard() }
                } else {
                    Button("Start Launcher") { controller.startLauncher() }
                }
            }
            Divider()
            Section("Services") {
                if controller.launcherRunning, !controller.services.isEmpty {
                    ForEach(controller.services, id: \.name) { svc in
                        HStack {
                            Circle()
                                .fill(svc.healthy ? Color.green : (svc.running ? Color.yellow : Color.gray))
                                .frame(width: 8, height: 8)
                            Text(svc.name)
                            Spacer()
                            if svc.running {
                                Button("Restart") { controller.restart(service: svc.name) }
                                Button("Stop") { controller.stop(service: svc.name) }
                            } else {
                                Button("Start") { controller.start(service: svc.name) }
                            }
                        }
                    }
                } else {
                    Text("No data yet").foregroundColor(.secondary)
                }
            }
            Divider()
            Button("Run Diagnostics") { controller.runDiagnostics() }
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
    }
}

@MainActor
final class LauncherController: ObservableObject {
    @Published var launcherRunning = false
    @Published var services: [ServiceStatus] = []

    private var process: Process?
    private var pollTimer: Timer?

    // MARK: Public actions
    func startLauncher() {
        // If control plane already alive, just mark running
        probeStatus { [weak self] ok in
            guard let self else { return }
            if ok {
                Task { @MainActor in
                    self.launcherRunning = true
                    self.beginPolling()
                }
                return
            }
            do {
                let url = try self.locateLauncherBinary()
                let p = Process()
                p.executableURL = url
                p.arguments = ["--no-build"]
                p.environment = ProcessInfo.processInfo.environment
                try p.run()
                self.process = p
                self.launcherRunning = true
                self.beginPolling(delayed: true)
            } catch {
                self.presentAlert(title: "Failed to start launcher", message: String(describing: error))
            }
        }
    }

    func stopLauncher() {
        // Ask control plane to shutdown gracefully
        post("http://127.0.0.1:9090/shutdown") { _ in }
        // Fallback: terminate spawned process
        if let p = process, p.isRunning {
            p.terminate()
        }
        process = nil
        launcherRunning = false
        services = []
        pollTimer?.invalidate(); pollTimer = nil
    }

    func openDashboard() {
        if let url = URL(string: "http://127.0.0.1:9090/status") {
            NSWorkspace.shared.open(url)
        }
    }

    func start(service name: String) { post("http://127.0.0.1:9090/start/\(name)") { _ in } }
    func stop(service name: String) { post("http://127.0.0.1:9090/stop/\(name)") { _ in } }
    func restart(service name: String) { post("http://127.0.0.1:9090/restart/\(name)") { _ in } }

    func runDiagnostics() {
        // Prefer the repo script if present (dev mode)
        if let script = locateDiagnosticsScript() {
            DispatchQueue.global().async {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                task.arguments = ["swift", script.path]
                let pipe = Pipe(); task.standardOutput = pipe; task.standardError = pipe
                do {
                    try task.run()
                    task.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let out = String(data: data, encoding: .utf8) ?? ""
                    Task { @MainActor in self.presentAlert(title: "Diagnostics", message: out) }
                } catch {
                    Task { @MainActor in self.presentAlert(title: "Diagnostics failed", message: String(describing: error)) }
                }
            }
            return
        }
        // Otherwise, try a quick status probe
        probeStatus { ok in Task { @MainActor in self.presentAlert(title: "Diagnostics", message: ok ? "Control plane reachable." : "Control plane not reachable.") } }
    }

    // MARK: Internal helpers
    private func beginPolling(delayed: Bool = false) {
        pollTimer?.invalidate()
        let start = Date().addingTimeInterval(delayed ? 1.5 : 0)
        pollTimer = Timer(fireAt: start, interval: 2.0, target: self, selector: #selector(poll), userInfo: nil, repeats: true)
        RunLoop.main.add(pollTimer!, forMode: .common)
        poll()
    }

    private func probeStatus(completion: @escaping (Bool) -> Void) {
        get("http://127.0.0.1:9090/status") { result in
            switch result {
            case .success(let data):
                // Expecting JSON array; treat any valid JSON payload as success
                let ok = (try? JSONSerialization.jsonObject(with: data)) != nil
                completion(ok)
            case .failure:
                completion(false)
            }
        }
    }

    @objc private func poll() {
        guard launcherRunning else { return }
        get("http://127.0.0.1:9090/status") { result in
            switch result {
            case .success(let data):
                if let decoded = try? JSONDecoder().decode([ServiceStatus].self, from: data) {
                    Task { @MainActor in self.services = decoded }
                }
            case .failure:
                Task { @MainActor in
                    self.launcherRunning = false
                    self.services = []
                }
            }
        }
    }

    private func locateLauncherBinary() throws -> URL {
        // 1) Packaged inside app bundle at Resources/Launcher/FountainAiLauncher
        if let res = Bundle.main.resourceURL?.appendingPathComponent("Launcher/FountainAiLauncher"),
           FileManager.default.isExecutableFile(atPath: res.path) {
            return res
        }
        // 2) Prebuilt in repo (developer mode)
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let devPath = cwd.appendingPathComponent("platform/FountainAILauncher/.build/release/FountainAiLauncher")
        if FileManager.default.isExecutableFile(atPath: devPath.path) {
            return devPath
        }
        // 3) As a last resort, attempt `swift run` via /usr/bin/env
        // Use a tiny shim script to keep a Process handle; here throw and ask user to precompile.
        throw NSError(domain: "FountainAILauncherApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Launcher binary not found. Run 'bash Scripts/precompile.sh' or package the app to embed the launcher binary."])
    }

    private func locateDiagnosticsScript() -> URL? {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let path = cwd.appendingPathComponent("Scripts/start-diagnostics.swift")
        return FileManager.default.fileExists(atPath: path.path) ? path : nil
    }

    private func presentAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = title
            alert.informativeText = message
            alert.runModal()
        }
    }

    private func get(_ url: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let u = URL(string: url) else { completion(.failure(NSError())); return }
        URLSession.shared.dataTask(with: u) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    private func post(_ url: String, completion: @escaping (Bool) -> Void) {
        guard let u = URL(string: url) else { completion(false); return }
        var req = URLRequest(url: u)
        req.httpMethod = "POST"
        URLSession.shared.dataTask(with: req) { _, resp, _ in
            let ok = (resp as? HTTPURLResponse)?.statusCode == 200
            completion(ok)
        }.resume()
    }
}

struct ServiceStatus: Codable, Hashable {
    let name: String
    let running: Bool
    let healthy: Bool
}
#endif
