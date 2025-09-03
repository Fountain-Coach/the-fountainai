# Toolsmith in Gateway/Codex Orchestration
> **Legacy:** Retained for historical reference after sandbox tooling was removed.

This guide shows how the Gateway/Codex loop imports and drives `toolsmith` to execute sandboxed tools.

## Importing and Instantiating

Add the package to `Package.swift` and import the libraries in your orchestrator:

```swift
.package(path: "./toolsmith")
```

```swift
import Toolsmith
import SandboxRunner

let toolsmith = Toolsmith()
let runner = BwrapRunner()
```

## Tool Call Lifecycle

The snippet below demonstrates the full `start → run → shutdown` flow of a tool call.

```swift
import Toolsmith
import SandboxRunner
import Foundation

let work = FileManager.default.temporaryDirectory.appendingPathComponent("work")
try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)

let toolsmith = Toolsmith()
let runner = BwrapRunner()

defer { try? FileManager.default.removeItem(at: work) }

let requestID = toolsmith.run(tool: "echo") {
    let result = try runner.run(
        executable: "/bin/echo",
        arguments: ["hello"],
        inputs: [],
        workDirectory: work,
        allowNetwork: false,
        timeout: 5,
        limits: nil
    )
    print(result.stdout)
}
```

## Client Generation

Run `scripts/generate-toolsmith-client.swift` to regenerate the `ToolsmithAPI` client from the shared `tools-factory.yml` spec. The generator copies the `Client/tools-factory` output into `toolsmith/Sources/ToolsmithAPI`, preserving operation names like `list_tools` and `register_openapi` so interfaces mirror the Tools Factory contract and avoid naming conflicts.

## Smoke Test

Verify an orchestrator ↔ sandbox round-trip with:

```bash
scripts/toolsmith-smoke-test.sh
```

## CLI Usage


With a Tool Server running and `TOOLSERVER_URL` set to its base URL, the `toolsmith-cli` utility can drive conversions:

```bash
export TOOLSERVER_URL=http://localhost:8080

# Check server health
toolsmith-cli health-check
# {"status":"ok"}

# Download the manifest
toolsmith-cli manifest
# prints manifest json

# Convert an image
toolsmith-cli convert-image path/to/sample.png out.jpg
# wrote out.jpg

# Transcode audio
toolsmith-cli transcode-audio path/to/sample.wav out.mp3
# wrote out.mp3

# Convert a plist
toolsmith-cli convert-plist path/to/sample.plist out.plist
# wrote out.plist
```

> © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
