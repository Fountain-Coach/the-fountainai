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
        run(command: ["bash", "Scripts/launcher", "start"], cwd: repoPath) { [weak self] code, out in
            DispatchQueue.main.async {
                self?.starting = false
                if code == 0 { self?.controlPlaneOK = true } else { self?.errorMessage = "Start failed. Check logs." }
            }
        }
    }

    func stop() {
        guard let repoPath else { return }
        run(command: ["bash", "Scripts/launcher", "stop"], cwd: repoPath) { [weak self] _, _ in
            DispatchQueue.main.async { self?.controlPlaneOK = false }
        }
    }

    func diagnostics() {
        guard let repoPath else { errorMessage = "Select repository first"; return }
        let script = URL(fileURLWithPath: repoPath).appendingPathComponent("Scripts/start-diagnostics.swift")
        if FileManager.default.fileExists(atPath: script.path) {
            runStreaming(command: ["swift", script.path], cwd: repoPath)
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

    private func run(command: [String], cwd: String, completion: @escaping (Int32, String) -> Void) {
        DispatchQueue.global().async {
            let proc = Process()
            proc.currentDirectoryURL = URL(fileURLWithPath: cwd)
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            proc.arguments = command
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

    private func runStreaming(command: [String], cwd: String) {
        let proc = Process()
        proc.currentDirectoryURL = URL(fileURLWithPath: cwd)
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        proc.arguments = command
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
                Button("Start") { vm.start() }
                    .disabled(vm.repoPath == nil || vm.starting)
                Button("Stop") { vm.stop() }
                Button("Diagnostics") { vm.diagnostics() }
                Button("Open Dashboard") { vm.openDashboard() }
                Spacer()
                Button("Copy Logs") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(vm.logText, forType: .string) }
            }
            Divider()
            TextEditor(text: Binding(get: { vm.logText }, set: { _ in }))
                .font(.system(.footnote, design: .monospaced))
                .disableAutocorrection(true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(16)
        .frame(minWidth: 720, minHeight: 420)
        .alert(item: Binding(get: {
            vm.errorMessage.map { Msg(text: $0) }
        }, set: { _ in vm.errorMessage = nil })) { msg in
            Alert(title: Text("Error"), message: Text(msg.text), dismissButton: .default(Text("OK")))
        }
    }
}

struct Msg: Identifiable { let id = UUID(); let text: String }
