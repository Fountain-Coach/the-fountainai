## GUI Apps: Build · Bundle · Launch (No Xcode)

This repository ships a repeatable pattern for SwiftUI GUI apps that launch without Xcode.

- Build (binary):
  - `swift build --product <Product>`
- Bundle (.app):
  - `bash Scripts/make_app.sh <Product>`
- Launch (GUI):
  - `open dist/<Product>.app`

On first launch your app can present onboarding if needed. The bundling flow works the same for any SwiftPM executable that uses SwiftUI.

### Why this works
- SwiftPM produces an executable binary for SwiftUI apps. `Scripts/make_app.sh` wraps any product into a proper macOS `.app` bundle with an Info.plist so you can open it via Finder or `open`.
- No Xcode project is required to run the app.

---

## Scaffolding New GUI Apps
Create new SwiftUI app targets that follow the same onboarding and adapter pattern.

1) Scaffold
- `Scripts/new-gui-app.sh <AppName> [BundleID]`

What it creates
- Target folder: `apps/<AppName>/main.swift` (SwiftUI + onboarding + minimal Ask view)
- Package wiring: adds a `.executable` product and `.executableTarget` for both lean/full graphs in `Package.swift`

2) Build, Bundle, Launch
- `swift build --product <AppName>`
- `bash Scripts/make_app.sh <AppName>`
- `open dist/<AppName>.app`

3) Onboarding contract
- One input (the critical credential, e.g., OpenAI API key)
- Saved to Keychain via `DefaultSettingsStore`
- Advanced settings remain hidden by default

---

## Adapter Pattern (Providers)

New providers plug in behind very small protocols in `FountainAICore`:

- `LLMService`: `chat(model:messages:) -> String`
- `BrowserService`: `analyze(url:corpusId:) -> (title, summary)`

Included adapters
- `OpenAIAdapter` (direct to OpenAI Chat Completions)
- `LLMGatewayAdapter` (HTTP gateway client)

Switching providers
- The app factory selects `OpenAIAdapter` when provider is `.openai` and a key is present, otherwise it falls back to a mock.

---

## Troubleshooting

- “app doesn’t open / is a CLI”
  - Ensure you ran the bundler: `bash Scripts/make_app.sh <Product>` then `open dist/<Product>.app`
- “permission denied” on scripts
  - Use bash invocation (execute bit not required): `bash Scripts/make_app.sh <Product>`
- “.alert cannot be used on type View”
  - Attach view modifiers to a concrete view (e.g., `Group { ... }.alert(...)`), not the protocol type.

---

## Summary

- One pattern for every GUI app: Build · Bundle · Launch
- Onboarding asks for a single credential; advanced settings are optional
- Scaffolder generates new app targets that conform to this pattern
