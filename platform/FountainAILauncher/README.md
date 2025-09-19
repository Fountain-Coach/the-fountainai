# 🚀 FountainAiLauncher

The `FountainAiLauncher` is a **cross-platform Swift CLI** that launches, monitors, and coordinates the execution of all FountainAI microservices, including:

- the **LLM Gateway** for model orchestration
- the **FountainAI Gateway** for API routing, HTTPS, and access control
- and the entire OpenAPI-based FountainAI service mesh

This launcher replaces Docker, `systemd`, and `launchd` with a single, lightweight, Swift-native supervisor. It is suitable for both macOS and Linux deployments.

This README covers operations and deployment. For the golden-key specification and development roadmap, see [agent.md](agent.md).

---

## 🔑 Required Environment

Before starting the launcher, export the FountainStore connection details:

- `FOUNTAINSTORE_URL`
- `FOUNTAINSTORE_API_KEY`

These are checked alongside `OPENAI_API_KEY` during diagnostics.

---

## 🎯 Features

- ✅ Cross-platform orchestration (macOS & Linux)
- 🌀 Launches all services as subprocesses
- 📄 Discovers service metadata from OpenAPI gateway specs
- 🔁 Optional auto-restart on failure
- 🌐 Optional `/status` and `/health` HTTP endpoint (coming soon)
- 📜 Logs directly to stdout or per-service log files
- 🔒 Requires no containers, no systemd, and no bash scripts

---

## 🧱 FountainAI Services Managed

| Service Name           | Executable Name        | Port  | Role Description |
|------------------------|------------------------|-------|------------------|
| Baseline Awareness     | `baseline-awareness`   | 8001  | Diff, drift, narrative patterns |
| Bootstrap              | `bootstrap`            | 8002  | Corpus and rules initializer |
| Planner                | `planner`              | 8003  | Delegates tasks and goals |
| Function Caller        | `function-caller`      | 8004  | Maps operationIds to HTTP |
| Persist                | `persist`              | 8005  | FountainStore-backed corpus storage |
| **LLM Gateway**        | `llm-gateway`          | 8006  | Connects to external LLMs (OpenAI, Claude) |
| Semantic Browser       | `semantic-browser`     | 8007  | Headless browsing and semantic dissection |
| **Gateway**            | `fountain-gateway`     | 8010  | HTTPS, authentication, route proxying |
| Tools Factory          | `tools-factory`        | 8011  | Registers callable OpenAPI tools |

---

## 📦 Project Layout

```
FountainAiLauncher/
├── Package.swift
├── agent.md                 ← Codex control file
├── README.md                ← This file
├── Sources/
│   └── FountainAiLauncher/
│       ├── main.swift
│       ├── Service.swift
│       ├── Supervisor.swift
│       └── HealthMonitor.swift  (optional)
└── Tests/
    └── FountainAiLauncherTests/
```

---

## 🗂 OpenAPI-based Service Discovery

FountainAI now includes automatic service discovery. The launcher and
`start-diagnostics.swift` scan `openapi/v*/` for `*-gateway.yml` files. Each
spec declares the executable name via `x-fountain.binary` and an optional
`x-fountain.port`. The first entry in `servers:` is used to determine the
service's base URL. Binaries are resolved relative to the
`FOUNTAINAI_SERVICES_DIR` environment variable (defaulting to
`/usr/local/bin`).

This removes the need for a manual `services.json` manifest.

---

## 🩺 Diagnostics

Run the Swift diagnostics script before launching to verify all service binaries and required API keys are available:

```bash
swift scripts/start-diagnostics.swift
```

---

## 🛠️ Usage

```bash
swift build -c release
.build/release/FountainAiLauncher
```

Or install:

```bash
cp .build/release/FountainAiLauncher /usr/local/bin/fountainai-launcher
fountainai-launcher
```

### Precompile Service Binaries for Fast Boot

Build all FountainAI service executables ahead of time and install them into `dist/bin`:

```bash
bash Scripts/precompile.sh
```

The launcher detects precompiled artifacts and will skip rebuilding on launch. You can control behavior with flags:

- `--precompile` – build + install binaries and exit
- `--no-build` – skip building and use existing binaries
- `--force-build` – always rebuild binaries

Artifacts:
- Binaries: `dist/bin/<service>`
- Manifest: `service-manifest.json`
- Signature: `dist/.launcher_signature`

---
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
