# SwiftCursesKit Agent

## Scope
This agent governs the entire repository. Add a more specific `AGENTS.md` inside a subdirectory if you need to override or extend these rules.

## Mission
Deliver a safe, expressive Swift wrapper around **ncurses** so developers can compose terminal dashboards and text-based user interfaces with declarative layouts, modern Swift concurrency, and predictable resource management.

## Repository Layout
- `Package.swift` → Declare the core library target `SwiftCursesKit`, a low-level bridging target `CNCursesSupport`, and any example executables.
- `Sources/SwiftCursesKit/` → Public API surface (windows, widgets, layout system, input handling, color management).
- `Sources/CNCursesSupport/` → Thin wrappers over C ncurses symbols; keep this module minimal and internal.
- `Examples/` → Sample terminal apps that demonstrate layout primitives and event handling.
- `Tests/SwiftCursesKitTests/` → Unit and integration tests covering rendering, input translation, and resource teardown.

## API & Style Guidelines
- Provide high-level types (`TerminalApp`, `Screen`, `Window`, `Panel`, `ColorPair`, `KeyEvent`) instead of exposing raw ncurses pointers.
- Encapsulate every ncurses resource (windows, pads, color pairs) inside a Swift type that owns initialization and cleanup (`deinit` or explicit `close()`).
- Keep global state confined to a single runtime coordinator; prefer dependency injection for testability.
- Favor value semantics for configuration objects and small view descriptors; use reference types only for long-lived controllers.
- Document every public symbol with Swift documentation comments and maintain DocC tutorials for end-to-end examples.
- Offer async-friendly APIs where appropriate (e.g., `async sequence` for input events, `Task`-based animation hooks).
- Use `swift-format` (with the project’s shared configuration) before committing changes.

## Interop Requirements
- Call ncurses only through `CNCursesSupport`. Centralize unsafe pointer operations there and wrap them with `Result`- or `throws`-based Swift APIs.
- Guard platform-specific features (mouse support, color depth detection) behind capability checks and expose them as optional Swift features.
- Provide shims for wide-character builds (`ncursesw`) and ensure the build script detects and links against the correct library on macOS and Linux.

## Testing & Quality Gates
1. `swift build`
2. `swift test`
3. `swift-format --in-place` on the entire repository (or the configured `mint run swiftformat` equivalent if we standardize on SwiftFormat).
4. Run `swift run Examples/DashboardDemo --recording` (or the latest integration example) before publishing releases to ensure rendering works against a real terminal.

A change is ready to merge only when all of the above succeed locally and in CI, public documentation is updated if behavior changes, and at least one example app showcases new widgets or layout features.
