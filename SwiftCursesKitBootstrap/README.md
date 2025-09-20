# SwiftCursesKit

SwiftCursesKit is a Swift-native wrapper around **ncurses** that lets you build rich, windowed dashboards directly in the terminal. It combines ncurses’ battle-tested capabilities (cursor control, colors, mouse input, panels) with ergonomic Swift APIs, async event loops, and declarative layout primitives.

https://github.com/your-org/swiftcurseskits (replace with the final repository URL)

---

## Features

- **Safe resource management** – Windows, panels, and color pairs are owned by Swift types that automatically initialize and tear down ncurses resources.
- **Declarative layout** – Compose split views, stacks, gauges, tables, and log panes with familiar Swift builders.
- **Async input handling** – Translate keystrokes, mouse events, and timers into structured `KeyEvent`/`MouseEvent` values.
- **Cross-platform** – Works on Linux and macOS (wide-character ncurses), with automatic capability detection.
- **Examples included** – Sample dashboards demonstrate live metrics, log streaming, and modal dialogs.

---

## Getting Started

### Prerequisites

- Swift 6.1 or newer

- `ncurses` development headers installed (`sudo apt install libncursesw5-dev` on Debian/Ubuntu, `brew install ncurses` on macOS)

### Installation

Add SwiftCursesKit to your `Package.swift`:

```swift
// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "MyTerminalApp",
    dependencies: [
        .package(url: "https://github.com/your-org/SwiftCursesKit.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "MyTerminalApp",
            dependencies: [
                .product(name: "SwiftCursesKit", package: "SwiftCursesKit")
            ]
        )
    ]
)
```

Then fetch dependencies:

```bash
swift package update
```

---

## Quick Start

```swift
import SwiftCursesKit

@main
struct DemoDashboard: TerminalApp {
    var body: some Scene {
        Screen {
            VStack(spacing: 1) {
                Title("SwiftCursesKit Demo")
                HStack {
                    Gauge(title: "CPU", value: cpuUsage)
                    Gauge(title: "Memory", value: memoryUsage)
                }
                LogView(lines: logBuffer)
                StatusBar(items: [
                    .label("q: quit"),
                    .label("f: toggle fullscreen")
                ])
            }
            .padding(1)
        }
    }

    func onEvent(_ event: Event, context: AppContext) async {
        switch event {
        case .key(.character("q")):
            await context.quit()
        case .tick:
            await context.updateMetrics()
        default:
            break
        }
    }
}
```

Run the demo:

```bash
swift run DemoDashboard
```

---

## Project Layout

```
.
├── Package.swift
├── Sources
│   ├── SwiftCursesKit        # Public Swift API
│   └── CNCursesSupport       # C shims and unsafe interop
├── Examples
│   └── DashboardDemo         # Reference terminal dashboard
└── Tests
    └── SwiftCursesKitTests   # Unit and integration tests
```

Refer to `AGENTS.md` for detailed contribution standards.

---

## Development Workflow

```bash
swift build
swift test
swift-format --in-place .
swift run Examples/DashboardDemo
```

Before submitting a pull request:

1. Verify that examples render correctly in a real terminal session.
2. Update DocC tutorials or inline documentation for new features.
3. Add regression tests for bug fixes and new widgets.

---

## Contributing

We welcome issues, feature ideas, and pull requests! Please read `AGENTS.md` for style, testing, and review expectations before contributing. Open a discussion if you plan to propose major architectural changes such as alternate renderers or event loops.

---

## License

SwiftCursesKit is released under the MIT License. See `LICENSE` for details.
