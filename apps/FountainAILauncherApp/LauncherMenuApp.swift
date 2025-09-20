import SwiftUI
import Foundation
import AppKit

#if os(macOS)
@main
struct LauncherMenuApp: App {
    @StateObject private var controller = LauncherController()
    @Environment(\.openWindow) private var openWindow

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
            Section("Tools") {
                Button("Set Repo Root…") { controller.chooseRepoRoot() }
                Button("Open Logs Folder") { controller.openLogsFolder() }
                Button("Show Status…") { openWindow(id: "status") }
            }
            Divider()
            Button("Run Diagnostics") { controller.runDiagnostics() }
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
        WindowGroup(id: "status") {
            StatusView(controller: controller)
        }
    }
}

@MainActor
final class LauncherController: ObservableObject {
    @Published var launcherRunning = false
    @Published var services: [ServiceStatus] = []

    private var process: Process?
    private var pollTimer: Timer?
    private let repoKey = "FountainAI.RootPath"

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
                var env = ProcessInfo.processInfo.environment
                // Prefer user-configured repo root; otherwise, try to infer from bundle
                if let repo = self.repoRoot() ?? self.locateRepoRootFromBundle() {
                    p.currentDirectoryURL = repo
                    let servicesDir = repo.appendingPathComponent("dist/bin", isDirectory: true)
                    env["FOUNTAINAI_SERVICES_DIR"] = servicesDir.path
                    env["FOUNTAINAI_ROOT"] = repo.path
                }
                p.environment = env
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
        let cwd = repoRoot() ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let devPath = cwd.appendingPathComponent("platform/FountainAILauncher/.build/release/FountainAiLauncher")
        if FileManager.default.isExecutableFile(atPath: devPath.path) {
            return devPath
        }
        // 3) As a last resort, attempt `swift run` via /usr/bin/env
        // Use a tiny shim script to keep a Process handle; here throw and ask user to precompile.
        throw NSError(domain: "FountainAILauncherApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Launcher binary not found. Run 'bash Scripts/precompile.sh' or package the app to embed the launcher binary."])
    }

    private func locateDiagnosticsScript() -> URL? {
        let cwd = repoRoot() ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let path = cwd.appendingPathComponent("Scripts/start-diagnostics.swift")
        return FileManager.default.fileExists(atPath: path.path) ? path : nil
    }

    private func locateRepoRootFromBundle() -> URL? {
        // App bundle path: <repo>/dist/FountainAILauncherApp.app
        // We want <repo>
        let bundle = Bundle.main.bundleURL
        let dist = bundle.deletingLastPathComponent()
        let repo = dist.deletingLastPathComponent()
        let pkg = repo.appendingPathComponent("Package.swift")
        let openapi = repo.appendingPathComponent("openapi")
        if FileManager.default.fileExists(atPath: pkg.path) && FileManager.default.fileExists(atPath: openapi.path) {
            return repo
        }
        return nil
    }

    private func presentAlert(title: String, message: String) {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
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

    // MARK: Preferences & Logs
    func chooseRepoRoot() {
        let panel = NSOpenPanel()
        panel.message = "Select the repository root (folder containing Package.swift and openapi/)"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let url = panel.url {
            if validateRepo(url) {
                UserDefaults.standard.set(url.path, forKey: repoKey)
                presentAlert(title: "Saved", message: "Repo root set to:\n\(url.path)")
            } else {
                presentAlert(title: "Invalid Repo", message: "Selected folder doesn't look like a FountainAI repo.")
            }
        }
    }

    func openLogsFolder() {
        let base = repoRoot() ?? locateRepoRootFromBundle()
        guard let repo = base else { presentAlert(title: "No Repo", message: "Set the repo root first."); return }
        let logs = repo.appendingPathComponent("logs", isDirectory: true)
        if !FileManager.default.fileExists(atPath: logs.path) {
            try? FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
        }
        NSWorkspace.shared.open(logs)
    }

    private func repoRoot() -> URL? {
        if let stored = UserDefaults.standard.string(forKey: repoKey), !stored.isEmpty {
            let url = URL(fileURLWithPath: stored, isDirectory: true)
            if validateRepo(url) { return url }
        }
        return nil
    }

    private func validateRepo(_ url: URL) -> Bool {
        let pkg = url.appendingPathComponent("Package.swift")
        let openapi = url.appendingPathComponent("openapi")
        return FileManager.default.fileExists(atPath: pkg.path) && FileManager.default.fileExists(atPath: openapi.path)
    }
}

// MARK: - Status Window

struct StatusView: View {
    @ObservedObject var controller: LauncherController
    @State private var now = Date()
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle().fill(controller.launcherRunning ? Color.green : Color.red).frame(width: 10, height: 10)
                Text(controller.launcherRunning ? "Launcher: Running" : "Launcher: Stopped")
                Spacer()
                Button(controller.launcherRunning ? "Stop" : "Start") {
                    controller.launcherRunning ? controller.stopLauncher() : controller.startLauncher()
                }
            }
            Divider()
            Text("Services:").bold()
            if controller.services.isEmpty {
                Text("No services reported yet.").foregroundColor(.secondary)
            } else {
                ForEach(controller.services, id: \.name) { svc in
                    HStack {
                        Circle().fill(svc.healthy ? Color.green : (svc.running ? Color.yellow : Color.gray)).frame(width: 8, height: 8)
                        Text(svc.name)
                        Spacer()
                        if svc.running { Button("Restart") { controller.restart(service: svc.name) }; Button("Stop") { controller.stop(service: svc.name) } }
                        else { Button("Start") { controller.start(service: svc.name) } }
                    }
                }
            }
            Divider()
            HStack { Button("Diagnostics") { controller.runDiagnostics() }; Spacer(); Button("Open Dashboard") { controller.openDashboard() } }
        }
        .padding(16)
        .frame(minWidth: 420, minHeight: 320)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                Task { @MainActor in now = Date() }
            }
        }
    }
}

struct ServiceStatus: Codable, Hashable {
    let name: String
    let running: Bool
    let healthy: Bool
}
#endif
