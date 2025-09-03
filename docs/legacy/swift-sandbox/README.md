# Swift Sandbox
> **Legacy:** Retained for historical reference after sandbox tooling was removed.

Quick-start guide for building and exercising the sandboxed Tool Server.

## Build

```bash
# Generate Ubuntu rootfs with bundled tools
./scripts/build-sandbox-image.sh swift-6.0.1-ubuntu22.04

# Compile Swift packages
swift build -c release
```

## Run

```bash
# Launch the Swift Tool Server locally
swift run ToolServer --port 8080
```

## Invoke a tool

```bash
curl -X POST http://localhost:8080/image/convert \
  -F input=@input.jpg \
  -F toFormat=png \
  -F width=1024 > out.png
```

## More

- License matrix: see [../docs/licensing-matrix.md](../docs/licensing-matrix.md).
- Test procedure: run [../scripts/run-tests.sh](../scripts/run-tests.sh).

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
