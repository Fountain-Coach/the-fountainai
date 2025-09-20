FountainAILauncherApp — macOS menubar controller for FountainAiLauncher

Build:
- swift build -c release --product FountainAILauncherApp

Package into .app and embed launcher binary:
- bash Scripts/package-launcher-app.sh

Use:
- Start Launcher: spawns the embedded `FountainAiLauncher` with `--no-build`
- Stop Launcher: posts `/shutdown` to the control plane or terminates the process
- Services: Start/Stop/Restart specific services via control plane endpoints
- Diagnostics: runs `Scripts/start-diagnostics.swift` in dev mode, otherwise probes control plane

