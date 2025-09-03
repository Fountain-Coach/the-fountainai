# 🧠 Swift Sandbox Agent Manifest
> **Legacy:** Retained for historical reference after sandbox tooling was removed.

**Last Updated:** September 15, 2025
**Scope:** `Swift-Sandbox`
**Purpose:** Guide development of the Swift‑centered tool sandbox and server.

---

## 🎯 Mission

Provide a portable Ubuntu sandbox that runs a Swift Tool Server exposing headless tools through OpenAPI 3.1. The service surface follows the existing `tools-factory` OpenAPI, while the LLM orchestrator interacts only with typed Swift clients, keeping orchestration fully Swift and Docker‑free.

## 📦 Components

- Ubuntu image with Swift 6 and curated tools (ImageMagick, ffmpeg, exiftool, pandoc, libplist; optional Csound, LilyPond).
- Swift Tool Server built on Swift NIO; no shell in the execution path.
- "FountainAI Toolsmith" SPM package with SandboxRunner and generated API clients built atop the `tools-factory` OpenAPI, avoiding naming collisions with that service.
- Deterministic, checksum‑pinned artifacts and reproducible builds.
- Markdown architecture diagrams (Mermaid) showing orchestrator → Tool Factory → sandbox flow.
- Package README with quick-start build and API examples.

## 🔐 Security & Isolation

- Namespaces backend using `bubblewrap` or `proot` (preferred) and a micro‑VM backend via QEMU for stronger isolation.
- Read‑only source mounts, write‑only scratch area, disabled network by default.
- Enforce cgroup limits (memory, cpu, pids) and optional seccomp profiles.

## ⚙️ Operational Guidelines

- OpenAPI specs live under `openapi` (e.g., `tools-factory.yml`); generated Swift clients and stubs reside in `Sources/openapi/Generated`.
- Structured logs must include `request_id`, `tool`, `args_hash`, `duration_ms`, and `exit_code`.
- Maintain `tools.json` manifest with image checksums, tool versions, and exposed operations.
- Ensure licensing compliance and provide source offers for bundled GPL/LGPL tools.
- License matrix tracked at `../docs/licensing-matrix.md`; run `./scripts/verify-licenses.sh` in CI.

## ✅ Acceptance & Testing

- `GET /_health` returns within 500ms; `GET /_manifest` lists tools and versions.
- Golden tests cover image resize, audio transcode, and plist conversion.
- Security tests reject writes outside `/work` and network access when disabled.
- Performance targets: cold bwrap start ≤150ms; micro‑VM snapshot ≤2s; 1MB JPEG→1024px PNG ≤500ms.
- `./scripts/build-sandbox-image.sh` and `swift build -c release` succeed.
- `./scripts/run-tests.sh` passes and reports coverage.

---

## 📁 Placement

Keep this file alongside `Agent-Development.md` and update it as requirements evolve.

> © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
