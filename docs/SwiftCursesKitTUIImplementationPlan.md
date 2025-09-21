# SwiftCursesKit Terminal UI Implementation Plan

## Background and References
- The existing macOS GUI path uses SwiftUI inside `FountainLauncherUI` to orchestrate repository management, service launches, and diagnostics shortcuts. Its `LauncherViewModel` drives tab-based navigation, scripts such as `Scripts/launcher`, and log streaming for the desktop experience.【F:apps/FountainLauncherUI/LauncherUIApp.swift†L1-L110】【F:apps/FountainLauncherUI/LauncherUIApp.swift†L111-L200】
- The repository already ships a SwiftCursesKit bootstrap kit with ncurses-oriented schemas, adapters, and prompts intended for whitespace-safe terminal UIs, demonstrating prior art for text-based dashboards.【F:SwiftCursesKitBootstrap/codex-whitespace-tui/README.md†L1-L61】【F:SwiftCursesKitBootstrap/codex-whitespace-tui/adapter/Swift/LLMAdapter.swift†L1-L120】

## Current Integration Status
- `SwiftCursesKit` v0.2.0 is now a package dependency of FountainAI, available to all targets (lean and full) for terminal UI work.【F:Package.swift†L1018-L1039】【F:Package.swift†L614-L628】
- A smoke-style integration test exercises widget measurement and rendering APIs to confirm we can compose gauges and status bars without requiring a live ncurses screen.【F:Tests/SwiftCursesKitIntegrationTests/SwiftCursesKitIntegrationTests.swift†L1-L47】

## Executable Task List
Each item can be run end-to-end on macOS or Linux terminals. Use the provided commands verbatim unless a task specifies templating.

1. **Environment bootstrap**
   - [ ] `tui-install-ncurses`
     - _Purpose_: Install the wide-character ncurses headers SwiftCursesKit links against.
     - _Command_: `brew install ncurses` (macOS) or `sudo apt-get update && sudo apt-get install -y libncursesw5-dev` (Linux).

2. **Create the Fountain terminal shell**
   - [ ] `tui-init-dashboard`
     - _Purpose_: Scaffold an executable target `FountainTUIDashboard` under `apps/FountainTUIDashboard` that mirrors the Launcher UI’s controls using SwiftCursesKit scenes.
     - _Command_: `swift package init --type executable --name FountainTUIDashboard --target-name FountainTUIDashboard --package-name the-fountainai` (run inside `apps` and then move generated files into place).
     - _Next_: Wire the target into `Package.swift` with `.executableTarget(name: "FountainTUIDashboard", dependencies: [.product(name: "SwiftCursesKit", package: "swiftcurseskit"), "FountainRuntime"])`.

3. **Model state synchronization**
   - [ ] `tui-sync-viewmodel`
     - _Purpose_: Port core logic from `LauncherViewModel` (repo discovery, script execution, log tailing, control plane polling) into an async SwiftCursesKit-friendly coordinator.
     - _Command_: `swift run swift-format --in-place apps/FountainTUIDashboard` after copying the relevant SwiftUI state machine to maintain style.
     - _Verification_: Add unit coverage that mocks `Process` execution and asserts the coordinator emits log/status updates similar to the macOS app.

4. **Screen composition**
   - [ ] `tui-build-scenes`
     - _Purpose_: Define reusable SwiftCursesKit scenes for tabs: control actions (start/stop), environment variables, and live log panes using `VStack`, `HStack`, `Split`, and `LogView` widgets.
     - _Command_: `swift test --filter FountainTUIDashboardTests.testControlTabLayout` (create a corresponding test target that snapshots render commands for a 120x40 terminal).

5. **Interaction loop**
   - [ ] `tui-wire-events`
     - _Purpose_: Implement `TerminalApp.onEvent` handlers for keyboard shortcuts (`q`, `s`, `x`, arrow navigation) and tick-based refresh of service status.
     - _Command_: `swift run FountainTUIDashboard --max-ticks 120 --preview` (support CLI flags to print a static preview for CI while still enabling interactive runs locally).

6. **Packaging and release**
   - [ ] `tui-bundle`
     - _Purpose_: Extend `Scripts/make_app.sh` or add a new script to produce a standalone binary bundle (tarball or `.pkg`) with ncurses dependency notes for macOS users.
     - _Command_: `Scripts/make_app.sh FountainTUIDashboard` (update script to support CLI-only packaging) followed by uploading the artifact to the release pipeline.

7. **Documentation and support**
   - [ ] `tui-docs`
     - _Purpose_: Document the TUI workflow (install deps, run preview, connect to control plane) alongside the existing GUI quickstart.
     - _Command_: `swift test --filter SwiftCursesKitIntegrationTests` (use the existing integration test to ensure widget APIs remain stable) and then add a tutorial under `docs/`.

Complete these tasks to ship a feature-parity terminal dashboard that reuses FountainAI’s orchestration logic while staying entirely inside the Swift toolchain.
