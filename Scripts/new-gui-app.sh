#!/usr/bin/env bash
set -euo pipefail

# new-gui-app.sh — scaffold a SwiftUI GUI app target in this monorepo
# Usage: Scripts/new-gui-app.sh <AppName> [BundleID]

APP_NAME=${1:-}
BUNDLE_ID=${2:-co.fountain.ai.${1:-app}}

if [[ -z "$APP_NAME" ]]; then
  echo "Usage: Scripts/new-gui-app.sh <AppName> [BundleID]" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/apps/$APP_NAME"

if [[ -e "$APP_DIR" ]]; then
  echo "Target directory already exists: $APP_DIR" >&2
  exit 1
fi

mkdir -p "$APP_DIR"

cat > "$APP_DIR/main.swift" <<'SWIFT'
import SwiftUI
import FountainAICore
import FountainAIAdapters

@main
struct AppEntry: App {
    @State private var settings = AppSettings()
    @State private var vm: AskViewModel? = nil
    @State private var settingsStore = DefaultSettingsStore(keychain: KeychainDefault())
    @State private var errorMessage: String? = nil
    @State private var showOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if showOnboarding {
                    OnboardingView(saveKey: { key in
                        if settings.apiKeyRef == nil || settings.apiKeyRef?.isEmpty == true {
                            settings.apiKeyRef = "openai-key"
                        }
                        saveLLMToken(key)
                        showOnboarding = false
                        configure()
                    })
                } else {
                    MainView(vm: vm, onAsk: ask)
                        .onAppear {
                            configure()
                            if settings.provider == .openai && !hasLLMToken() { showOnboarding = true }
                        }
                }
            }
            .alert(item: Binding(get: { errorMessage.map { Msg(text: $0) } }, set: { _ in })) { msg in
                Alert(title: Text("Error"), message: Text(msg.text), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func hasLLMToken() -> Bool {
        guard let ref = settings.apiKeyRef, !ref.isEmpty else { return false }
        if let data = try? settingsStore.getSecret(for: ref) { return !data.isEmpty }
        return false
    }

    private func saveLLMToken(_ token: String) {
        guard let ref = settings.apiKeyRef, !ref.isEmpty else { errorMessage = "Set LLM API Key Ref first"; return }
        do { try settingsStore.setSecret(Data(token.utf8), for: ref) } catch { errorMessage = String(describing: error) }
    }

    private func makeLLM() -> LLMService {
        let token: String? = (try? settingsStore.getSecret(for: settings.apiKeyRef ?? "")).flatMap { String(data: $0, encoding: .utf8) }
        switch settings.provider {
        case .openai:
            if let token, !token.isEmpty {
                return OpenAIAdapter(apiKey: token)
            } else {
                return MockLLMService()
            }
        case .customHTTP, .localServer:
            guard let urlStr = settings.baseURL, let url = URL(string: urlStr) else { return MockLLMService() }
            let client = LLMGatewayClient(baseURL: url, bearerToken: token)
            return LLMGatewayAdapter(client: client)
        }
    }

    private func configure() {
        do { settings = try settingsStore.load() } catch { }
        let llm = makeLLM()
        vm = AskViewModel(llm: llm, browser: MockBrowserService())
    }

    private func ask(_ question: String) async -> String {
        guard let vm else { return "No VM" }
        await vm.ask(question: question)
        return await vm.answer
    }
}

struct MainView: View {
    let vm: AskViewModel?
    let onAsk: (String) async -> String
    @State private var q = ""
    @State private var a = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ask").font(.title2)
            TextField("Your question", text: $q)
            Button("Get Answer") { Task { a = await onAsk(q) } }
            Divider()
            ScrollView { Text(a).frame(maxWidth: .infinity, alignment: .leading) }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct OnboardingView: View {
    var saveKey: (String) -> Void
    @State private var key = ""
    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome").font(.title)
            SecureField("OpenAI API Key", text: $key)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 420)
            Button("Continue") { saveKey(key) }
                .buttonStyle(.borderedProminent)
                .disabled(key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .frame(maxWidth: 420)
        }
        .padding(32)
        .frame(minWidth: 500, minHeight: 300)
    }
}

struct Msg: Identifiable { let id = UUID(); let text: String }

final class MockLLMService: LLMService {
    func chat(model: String, messages: [FountainAICore.ChatMessage]) async throws -> String {
        return "(mock) " + (messages.last?.content ?? "")
    }
}
final class MockBrowserService: BrowserService {
    func analyze(url: String, corpusId: String?) async throws -> (title: String?, summary: String?) { (nil, nil) }
}
SWIFT

# Update Package.swift: add product and targets (lean/full)
PKG_FILE="$ROOT_DIR/Package.swift"

insert_product() {
  local varname="$1"
  local name="$2"
  awk -v VARNAME="$varname" -v APP="$name" '
    BEGIN{inblock=0}
    {
      printline=$0
      if ($0 ~ "let " VARNAME "[^"]*\[Product\] = \[") { inblock=1 }
      if (inblock && $0 ~ /^\]/) {
        printf("    .executable(name: \"%s\", targets: [\"%s\"]),\n", APP, APP)
        inblock=0
      }
      print printline
    }
  ' "$PKG_FILE" > "$PKG_FILE.tmp" && mv "$PKG_FILE.tmp" "$PKG_FILE"
}

insert_target() {
  local varname="$1"
  local name="$2"
  awk -v VARNAME="$varname" -v APP="$name" '
    BEGIN{inblock=0}
    {
      printline=$0
      if ($0 ~ "let " VARNAME "[^"]*\[Target\] = \[") { inblock=1 }
      if (inblock && $0 ~ /^\]/) {
        printf("    .executableTarget(\n        name: \"%s\",\n        dependencies: [\"FountainAIAdapters\", \"FountainAICore\"],\n        path: \"apps/%s\"\n    ),\n", APP, APP)
        inblock=0
      }
      print printline
    }
  ' "$PKG_FILE" > "$PKG_FILE.tmp" && mv "$PKG_FILE.tmp" "$PKG_FILE"
}

insert_product fullProducts "$APP_NAME"
insert_product leanProducts "$APP_NAME"
insert_target fullTargets "$APP_NAME"
insert_target leanTargets "$APP_NAME"

echo "Scaffolded GUI app target: $APP_NAME"
echo "Path: apps/$APP_NAME/main.swift"
echo "Add bundle with: bash Scripts/make_app.sh $APP_NAME && open dist/$APP_NAME.app"

