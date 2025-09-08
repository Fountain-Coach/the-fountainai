# Q&A: GUI Apps without Xcode + Scaffolding

**Q: I see a “Command Line Tool” label in Xcode. Is this not a GUI?**  
A: SwiftPM executable targets appear as “Command Line Tool” even for SwiftUI apps. The UI runs normally. To get a clickable bundle, run `bash Scripts/make_app.sh <Product>` and `open dist/<Product>.app`.

**Q: How do I launch a GUI app without Xcode?**  
A: Build → Bundle → Launch:
- `swift build --product FountainAIApp`
- `bash Scripts/make_app.sh FountainAIApp`
- `open dist/FountainAIApp.app`

**Q: What does onboarding ask for?**  
A: Exactly one field: the OpenAI API key. Paste and continue. The app stores it in Keychain and selects the OpenAI adapter automatically.

**Q: Can I create another app with the same experience?**  
A: Yes. Use the scaffolder:
- `Scripts/new-gui-app.sh <AppName>`
- `swift build --product <AppName>`
- `bash Scripts/make_app.sh <AppName>`
- `open dist/<AppName>.app`

**Q: I get “permission denied” when running a script.**  
A: Call with bash: `bash Scripts/make_app.sh <Product>` or make scripts executable once: `chmod +x Scripts/*.sh`.

**Q: I want a different provider (not OpenAI).**  
A: Implement `LLMService` and select it in the app factory. The scaffolder already wires a minimal factory; plug in your adapter and keep onboarding to one critical input.

**Q: Where is the full guide?**  
A: See `docs/GUI_App_Quickstart_and_Scaffolding.md` for the end‑to‑end workflow.

