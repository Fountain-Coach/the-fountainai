import SwiftUI
import AppKit
import Foundation

@main
struct LauncherUIApp: App {
    @StateObject private var vm = LauncherViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView(vm: vm)
        }
    }
}

@MainActor
final class LauncherViewModel: ObservableObject {
    @Published var repoPath: String? {
        didSet { UserDefaults.standard.set(repoPath, forKey: Self.repoKey) }
    }
    @Published var starting: Bool = false
    @Published var running: Bool = false
    @Published var controlPlaneOK: Bool = false
    @Published var logText: String = ""
    @Published var errorMessage: String? = nil

    private var tailProc: Process?
    private var statusTimer: Timer?
    enum BuildMode: Hashable { case auto, noBuild, forceBuild }
    @Published var buildMode: BuildMode = .auto

    static let repoKey = "FountainAI.RepoRoot"
    private let ctrlURL = URL(string: "http://127.0.0.1:9090/status")!

    init() {
        if let saved = UserDefaults.standard.string(forKey: Self.repoKey), !saved.isEmpty {
            repoPath = saved
        }
        startStatusPolling()
        startTailingLogs()
    }

    func chooseRepo() {
        let panel = NSOpenPanel()
        panel.message = "Select the FountainAI repository root"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let url = panel.url {
            let pkg = url.appendingPathComponent("Package.swift")
            let openapi = url.appendingPathComponent("openapi")
            guard FileManager.default.fileExists(atPath: pkg.path), FileManager.default.fileExists(atPath: openapi.path) else {
                errorMessage = "Selected folder is not a FountainAI repo (missing Package.swift or openapi/)"
                return
            }
            repoPath = url.path
            startTailingLogs(reset: true)
        }
    }

    func start() {
        guard let repoPath else { errorMessage = "Select repository first"; return }
        starting = true
        var args = ["bash", "Scripts/launcher", "start"]
        switch buildMode { case .auto: break; case .noBuild: args.append("--no-build"); case .forceBuild: args.append("--force-build") }
        run(command: args, cwd: repoPath, env: processEnv()) { [weak self] code, out in
            DispatchQueue.main.async {
                self?.starting = false
                if code == 0 { self?.controlPlaneOK = true } else { self?.errorMessage = "Start failed. Check logs." }
            }
        }
    }

    func stop() {
        guard let repoPath else { return }
        run(command: ["bash", "Scripts/launcher", "stop"], cwd: repoPath, env: processEnv()) { [weak self] _, _ in
            DispatchQueue.main.async { self?.controlPlaneOK = false }
        }
    }

    func diagnostics() {
        guard let repoPath else { errorMessage = "Select repository first"; return }
        let script = URL(fileURLWithPath: repoPath).appendingPathComponent("Scripts/start-diagnostics.swift")
        if FileManager.default.fileExists(atPath: script.path) {
            runStreaming(command: ["swift", script.path], cwd: repoPath, env: processEnv())
        } else {
            // Fallback: probe control plane
            Task { [weak self] in
                do {
                    _ = try await URLSession.shared.data(from: self!.ctrlURL)
                    await MainActor.run { self?.presentAlert(title: "Diagnostics", message: "Control plane reachable.") }
                } catch {
                    await MainActor.run { self?.presentAlert(title: "Diagnostics", message: "Control plane not reachable.") }
                }
            }
        }
    }

    func openDashboard() {
        NSWorkspace.shared.open(ctrlURL)
    }

    private func run(command: [String], cwd: String, env: [String: String]? = nil, completion: @escaping (Int32, String) -> Void) {
        DispatchQueue.global().async {
            let proc = Process()
            proc.currentDirectoryURL = URL(fileURLWithPath: cwd)
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            proc.arguments = command
            if let env { proc.environment = ProcessInfo.processInfo.environment.merging(env) { _, new in new } }
            let pipe = Pipe(); proc.standardOutput = pipe; proc.standardError = pipe
            do {
                try proc.run()
                proc.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let out = String(data: data, encoding: .utf8) ?? ""
                completion(proc.terminationStatus, out)
            } catch {
                completion(1, String(describing: error))
            }
        }
    }

    private func runStreaming(command: [String], cwd: String, env: [String: String]? = nil) {
        let proc = Process()
        proc.currentDirectoryURL = URL(fileURLWithPath: cwd)
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        proc.arguments = command
        if let env { proc.environment = ProcessInfo.processInfo.environment.merging(env) { _, new in new } }
        let pipe = Pipe(); proc.standardOutput = pipe; proc.standardError = pipe
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let self else { return }
            let data = handle.availableData
            if data.isEmpty { return }
            let chunk = String(decoding: data, as: UTF8.self)
            Task { @MainActor in
                var s = self.logText + chunk
                if s.count > 20000 { s = String(s.suffix(20000)) }
                self.logText = s
            }
        }
        try? proc.run()
    }

    // Build environment for child processes: secrets from Keychain, URLs from defaults
    private func processEnv() -> [String: String] {
        var env: [String: String] = [:]
        if let url = UserDefaults.standard.string(forKey: "FountainAI.FOUNTAINSTORE_URL"), !url.isEmpty {
            env["FOUNTAINSTORE_URL"] = url
        }
        if let openai = KeychainHelper.read(service: "FountainAI", account: "OPENAI_API_KEY") { env["OPENAI_API_KEY"] = openai }
        if let storeKey = KeychainHelper.read(service: "FountainAI", account: "FOUNTAINSTORE_API_KEY") { env["FOUNTAINSTORE_API_KEY"] = storeKey }
        return env
    }

    func precompile() {
        guard let repoPath else { errorMessage = "Select repository first"; return }
        runStreaming(command: ["bash", "Scripts/launcher", "precompile"], cwd: repoPath, env: processEnv())
    }

    // MARK: - Environment Management
    @Published var openAIKeyInput: String = ""
    @Published var storeURLInput: String = UserDefaults.standard.string(forKey: "FountainAI.FOUNTAINSTORE_URL") ?? ""
    @Published var storeKeyInput: String = ""
    func saveEnv() {
        if !openAIKeyInput.isEmpty { _ = KeychainHelper.save(service: "FountainAI", account: "OPENAI_API_KEY", secret: openAIKeyInput); openAIKeyInput = "" }
        if !storeKeyInput.isEmpty { _ = KeychainHelper.save(service: "FountainAI", account: "FOUNTAINSTORE_API_KEY", secret: storeKeyInput); storeKeyInput = "" }
        UserDefaults.standard.set(storeURLInput, forKey: "FountainAI.FOUNTAINSTORE_URL")
    }
    func clearOpenAIKey() { _ = KeychainHelper.delete(service: "FountainAI", account: "OPENAI_API_KEY") }
    func clearStoreKey() { _ = KeychainHelper.delete(service: "FountainAI", account: "FOUNTAINSTORE_API_KEY") }
    func exportDotEnv() {
        guard let repoPath else { errorMessage = "Select repository first"; return }
        var lines: [String] = []
        if let v = UserDefaults.standard.string(forKey: "FountainAI.FOUNTAINSTORE_URL"), !v.isEmpty { lines.append("FOUNTAINSTORE_URL=\(v)") }
        if let v = KeychainHelper.read(service: "FountainAI", account: "OPENAI_API_KEY"), !v.isEmpty { lines.append("OPENAI_API_KEY=\(v)") }
        if let v = KeychainHelper.read(service: "FountainAI", account: "FOUNTAINSTORE_API_KEY"), !v.isEmpty { lines.append("FOUNTAINSTORE_API_KEY=\(v)") }
        let content = lines.joined(separator: "\n") + "\n"
        let url = URL(fileURLWithPath: repoPath).appendingPathComponent(".env")
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
            presentAlert(title: ".env saved", message: url.path)
        } catch {
            presentAlert(title: "Failed to write .env", message: String(describing: error))
        }
    }
    private func startStatusPolling() {
        statusTimer?.invalidate()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task {
                do {
                    let (_, resp) = try await URLSession.shared.data(from: self.ctrlURL)
                    let ok = (resp as? HTTPURLResponse)?.statusCode == 200
                    await MainActor.run { self.controlPlaneOK = ok }
                } catch {
                    await MainActor.run { self.controlPlaneOK = false }
                }
            }
        }
    }

    private func startTailingLogs(reset: Bool = false) {
        tailProc?.terminate(); tailProc = nil
        guard let repoPath else { return }
        let logURL = URL(fileURLWithPath: repoPath).appendingPathComponent("logs/launcher.out")
        if !FileManager.default.fileExists(atPath: logURL.path) {
            FileManager.default.createFile(atPath: logURL.path, contents: nil)
        }
        let proc = Process(); tailProc = proc
        proc.currentDirectoryURL = URL(fileURLWithPath: repoPath)
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        proc.arguments = ["tail", "-n", "200", "-f", logURL.path]
        let pipe = Pipe(); proc.standardOutput = pipe; proc.standardError = pipe
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let self else { return }
            let data = handle.availableData
            if data.isEmpty { return }
            let chunk = String(decoding: data, as: UTF8.self)
            DispatchQueue.main.async {
                var s = self.logText + chunk
                if s.count > 20000 { s = String(s.suffix(20000)) }
                self.logText = s
            }
        }
        try? proc.run()
    }

    private func presentAlert(title: String, message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}

struct ContentView: View {
    @ObservedObject var vm: LauncherViewModel
    var body: some View {
        TabView {
            ControlTab(vm: vm)
                .tabItem { Label("Control", systemImage: "switch.2") }
            EnvTab(vm: vm)
                .tabItem { Label("Environment", systemImage: "key.fill") }
        }
        .frame(minWidth: 760, minHeight: 480)
    }
}

struct Msg: Identifiable { let id = UUID(); let text: String }

// MARK: - Tabs
struct ControlTab: View {
    @ObservedObject var vm: LauncherViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle().fill(vm.controlPlaneOK ? Color.green : Color.red).frame(width: 12, height: 12)
                Text(vm.controlPlaneOK ? "Control plane: reachable" : "Control plane: not reachable")
                Spacer()
            }
            HStack {
                if let repo = vm.repoPath {
                    Text("Repo: \(repo)").font(.footnote).foregroundColor(.secondary)
                } else {
                    Text("Repo: not set").font(.footnote).foregroundColor(.secondary)
                }
                Spacer()
                Button("Choose Repo…") { vm.chooseRepo() }
            }
            HStack(spacing: 12) {
                Picker("Build Mode", selection: Binding(get: { vm.buildMode }, set: { vm.buildMode = $0 })) {
                    Text("Auto").tag(LauncherViewModel.BuildMode.auto)
                    Text("No Build").tag(LauncherViewModel.BuildMode.noBuild)
                    Text("Force Build").tag(LauncherViewModel.BuildMode.forceBuild)
                }.pickerStyle(.segmented)
                Spacer()
                Button("Precompile") { vm.precompile() }.disabled(vm.repoPath == nil)
            }
            HStack(spacing: 12) {
                Button("Start") { vm.start() }
                    .disabled(vm.repoPath == nil || vm.starting)
                Button("Stop") { vm.stop() }
                Button("Diagnostics") { vm.diagnostics() }
                Button("Open Dashboard") { vm.openDashboard() }
                Spacer()
                Button("Copy Logs") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(vm.logText, forType: .string) }
            }
            Divider()
            GroupBox(label: Text("Logs")) {
                TextEditor(text: Binding(get: { vm.logText }, set: { _ in }))
                    .font(.system(.footnote, design: .monospaced))
                    .disableAutocorrection(true)
                    .frame(maxWidth: .infinity, minHeight: 260)
            }
        }
        .padding(16)
    }
}

struct EnvTab: View {
    @ObservedObject var vm: LauncherViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox(label: Text("Environment")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack { SecureField("OPENAI_API_KEY", text: $vm.openAIKeyInput); Button("Clear") { vm.clearOpenAIKey() } }
                    HStack { TextField("FOUNTAINSTORE_URL", text: $vm.storeURLInput) }
                    HStack { SecureField("FOUNTAINSTORE_API_KEY", text: $vm.storeKeyInput); Button("Clear") { vm.clearStoreKey() } }
                    HStack {
                        Button("Save Env") { vm.saveEnv() }
                        Button("Export .env (0600)") { vm.exportDotEnv() }
                        Spacer()
                        Button("Copy Sanitized") {
                            let hasOA = KeychainHelper.read(service: "FountainAI", account: "OPENAI_API_KEY") != nil
                            let hasFS = KeychainHelper.read(service: "FountainAI", account: "FOUNTAINSTORE_API_KEY") != nil
                            let url = UserDefaults.standard.string(forKey: "FountainAI.FOUNTAINSTORE_URL") ?? ""
                            let report = "Env Report\nOPENAI_API_KEY=\(hasOA ? "***" : "(missing)")\nFOUNTAINSTORE_URL=\(url.isEmpty ? "(missing)" : url)\nFOUNTAINSTORE_API_KEY=\(hasFS ? "***" : "(missing)")\n"
                            NSPasteboard.general.clearContents(); NSPasteboard.general.setString(report, forType: .string)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(16)
    }
}
