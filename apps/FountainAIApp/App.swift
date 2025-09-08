import SwiftUI
import FountainAICore
import FountainAIAdapters
import LLMGatewayAPI
import SemanticBrowserAPI
import PersistAPI

@main
struct FountainAIApp: App {
    @State private var settings = AppSettings()
    @State private var vm: AskViewModel? = nil
    @State private var settingsStore = DefaultSettingsStore(keychain: KeychainDefault())
    @State private var errorMessage: String? = nil
    @State private var browserURL: String = ""
    @State private var llmTokenInput: String = ""
    @State private var persistTokenInput: String = ""

    init() {
        // Load settings if available
        do { _settings = State(initialValue: try settingsStore.load()) } catch { }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(settings: $settings,
                        browserURL: $browserURL,
                        llmTokenInput: $llmTokenInput,
                        persistTokenInput: $persistTokenInput,
                        saveLLMToken: saveLLMToken,
                        savePersistToken: savePersistToken,
                        vm: vm,
                        onSave: configure)
                .onAppear { configure() }
                .alert(item: Binding(get: {
                    errorMessage.map { Msg(text: $0) }
                }, set: { _ in }), content: { msg in
                    Alert(title: Text("Error"), message: Text(msg.text), dismissButton: .default(Text("OK")))
                })
        }
    }

    private func configure() {
        do {
            // Persist settings
            try settingsStore.save(settings)
            // Build adapters
            let llmClient: LLMService = makeLLM(settings)
            let browserClient: BrowserService = makeBrowser()
            let persistClient: PersistenceService? = makePersist(settings)
            vm = AskViewModel(llm: llmClient, browser: browserClient, persistence: persistClient)
        } catch {
            errorMessage = String(describing: error)
        }
    }

    private func makeLLM(_ s: AppSettings) -> LLMService {
        switch s.provider {
        case .openai, .customHTTP, .localServer:
            guard let urlStr = s.baseURL, let url = URL(string: urlStr) else {
                return MockLLMService()
            }
            let token: String? = (try? settingsStore.getSecret(for: s.apiKeyRef ?? ""))
                .flatMap { String(data: $0, encoding: .utf8) }
            var headers: [String:String] = [:]
            if let token, !token.isEmpty { headers["Authorization"] = "Bearer \(token)" }
            let client = LLMGatewayClient(baseURL: url, bearerToken: token)
            return LLMGatewayAdapter(client: client)
        }
    }

    private func makeBrowser() -> BrowserService {
        guard !browserURL.isEmpty, let url = URL(string: browserURL) else {
            return MockBrowserService()
        }
        let client = SemanticBrowserClient(baseURL: url)
        return SemanticBrowserAdapter(client: client)
    }

    private func makePersist(_ s: AppSettings) -> PersistenceService? {
        switch s.persist {
        case .embedded(let path):
            return FilePersistenceAdapter(rootPath: (path as NSString).expandingTildeInPath)
        case .remote(let urlStr, let keyRef):
            guard let url = URL(string: urlStr) else { return nil }
            let key: String? = (try? settingsStore.getSecret(for: keyRef ?? ""))
                .flatMap { String(data: $0, encoding: .utf8) }
            let client = PersistClient(baseURL: url, apiKey: key)
            return PersistReflectionsAdapter(client: client)
        }
    }

    private func saveLLMToken(_ token: String) {
        guard let ref = settings.apiKeyRef, !ref.isEmpty else { errorMessage = "Set LLM API Key Ref first"; return }
        do { try settingsStore.setSecret(Data(token.utf8), for: ref) } catch { errorMessage = String(describing: error) }
    }

    private func savePersistToken(_ token: String) {
        if case .remote(let url, let keyRef) = settings.persist {
            guard let ref = keyRef, !ref.isEmpty else { errorMessage = "Set Persist API Key Ref first"; return }
            do { try settingsStore.setSecret(Data(token.utf8), for: ref); settings.persist = .remote(url: url, apiKeyRef: ref) } catch { errorMessage = String(describing: error) }
        } else {
            errorMessage = "Persist mode is Embedded; switch to Remote to save token"
        }
    }
}

struct Msg: Identifiable { let id = UUID(); let text: String }

struct ContentView: View {
    @Binding var settings: AppSettings
    @Binding var browserURL: String
    @Binding var llmTokenInput: String
    @Binding var persistTokenInput: String
    let saveLLMToken: (String) -> Void
    let savePersistToken: (String) -> Void
    let vm: AskViewModel?
    var onSave: () -> Void
    @State private var question = ""
    @State private var link = ""
    @State private var result = ""
    @State private var stateText = "idle"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FountainAI (macOS)").font(.title2)
            Form {
                Section(header: Text("Model")) {
                    Picker("Provider", selection: $settings.provider) {
                        Text("OpenAI").tag(ModelProvider.openai)
                        Text("Custom HTTP").tag(ModelProvider.customHTTP)
                        Text("Local Server").tag(ModelProvider.localServer)
                    }
                    TextField("Model name", text: $settings.modelName)
                    TextField("LLM Base URL", text: Binding(get:{ settings.baseURL ?? "" }, set:{ settings.baseURL = $0 }))
                    HStack {
                        TextField("LLM API Key Ref (Keychain account)", text: Binding(get:{ settings.apiKeyRef ?? "" }, set:{ settings.apiKeyRef = $0.isEmpty ? nil : $0 }))
                    }
                    HStack {
                        SecureField("LLM API Key (will be saved to Keychain)", text: $llmTokenInput)
                        Button("Save LLM Token") { saveLLMToken(llmTokenInput); llmTokenInput = "" }
                    }
                }
                Section(header: Text("Persistence")) {
                    Picker("Mode", selection: Binding(get: {
                        switch settings.persist { case .embedded: return 0; case .remote: return 1 }
                    }, set: { idx in
                        switch idx { case 0: settings.persist = .embedded(path: (NSHomeDirectory() as NSString).appendingPathComponent("Library/Application Support/FountainAI"));
                                     default: settings.persist = .remote(url: "http://persist.local", apiKeyRef: nil) }
                    })) {
                        Text("Embedded").tag(0); Text("Remote").tag(1)
                    }
                    switch settings.persist {
                    case .embedded(let path):
                        TextField("Embedded Path", text: Binding(get:{ path }, set:{ settings.persist = .embedded(path: $0) }))
                    case .remote(let url, let kref):
                        TextField("Persist URL", text: Binding(get:{ url }, set:{ settings.persist = .remote(url: $0, apiKeyRef: kref) }))
                        TextField("Persist API Key Ref (Keychain account)", text: Binding(get:{ kref ?? "" }, set:{ settings.persist = .remote(url: url, apiKeyRef: $0.isEmpty ? nil : $0) }))
                        HStack {
                            SecureField("Persist API Key (save to Keychain)", text: $persistTokenInput)
                            Button("Save Persist Token") { savePersistToken(persistTokenInput); persistTokenInput = "" }
                        }
                    }
                    TextField("Corpus ID", text: $settings.corpusId)
                }
                Section(header: Text("Semantic Browser")) {
                    TextField("Browser Base URL", text: $browserURL)
                }
            }
            HStack {
                Button("Save Settings", action: onSave)
                Spacer()
            }
            Divider()
            TextField("Ask a question", text: $question)
            TextField("Optional URL for context", text: $link)
            HStack {
                Button("Get Answer") { Task { await ask() } }
                Text("State: \(stateText)").foregroundColor(.secondary)
            }
            ScrollView { Text(result).frame(maxWidth: .infinity, alignment: .leading) }
        }
        .padding()
        .frame(minWidth: 700, minHeight: 500)
    }

    private func ask() async {
        guard let vm = vm else { stateText = "no vm"; return }
        await vm.ask(question: question, url: link, model: settings.modelName, corpusId: settings.corpusId)
        let st = await vm.state
        switch st {
        case .idle: stateText = "idle"
        case .working: stateText = "working"
        case .done: stateText = "done"
        case .failed(let m): stateText = "failed: \(m)"
        }
        result = await vm.answer
    }
}

// MARK: - Simple mocks and file persistence for embedded mode

final class MockLLMService: LLMService {
    func chat(model: String, messages: [ChatMessage]) async throws -> String {
        return "(mock) Answer for model=\(model) based on: " + (messages.last?.content ?? "")
    }
}

final class MockBrowserService: BrowserService {
    func analyze(url: String, corpusId: String?) async throws -> (title: String?, summary: String?) {
        return ("Mock Title", "Mock summary for \(url)")
    }
}

final class FilePersistenceAdapter: PersistenceService {
    let root: String
    init(rootPath: String) { self.root = rootPath }
    func save(question: String, url: String?, answer: String, sourceURL: String?, sourceTitle: String?, corpusId: String?) async throws {
        let dir = URL(fileURLWithPath: root)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let ts = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let obj: [String: Any?] = [
            "question": question, "url": url, "answer": answer,
            "sourceURL": sourceURL, "sourceTitle": sourceTitle, "corpusId": corpusId,
            "at": ts
        ]
        let data = try JSONSerialization.data(withJSONObject: obj.compactMapValues { $0 }, options: [.prettyPrinted])
        try data.write(to: dir.appendingPathComponent("session-\(ts).json"))
    }
}

// Needed to access NSApplication from SwiftUI
// No AppDelegate required; use SwiftUI state and pass dependencies explicitly.
