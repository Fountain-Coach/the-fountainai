# 🧠 Codex Agent: FountainAiLauncher – Golden-Key Boot & Supervisor

This specification turns `FountainAiLauncher` into the single **boot, runtime, and maintenance** application for FountainAI.
The former `scripts/boot.sh` is retired; all setup and execution go through this Swift executable.
Any service started outside the launcher must refuse to run.

For runtime usage and deployment instructions, consult [README.md](README.md).

---

## 🎯 Mission
- Act as the "golden key" for the whole system: without the launcher, FountainAI **cannot** start.
- Perform **build‑time** environment and security checks, build all services, install binaries, and record cryptographic fingerprints.
- Provide **runtime** supervision, health monitoring, and a small control plane for maintenance commands.

---

## 🧱 Build-Time Responsibilities
1. Load `.env` (or injected environment) and verify required secrets:
   - `OPENAI_API_KEY`
   - `FOUNTAINSTORE_URL`
   - `FOUNTAINSTORE_API_KEY`
   - any gateway credentials and TLS config
2. Run diagnostics equivalent to `scripts/start-diagnostics.swift`.
3. Execute `swift build --configuration release` for every package.
4. Install or symlink resulting binaries according to `services.json`.
5. Generate a manifest of SHA-256 hashes and file permissions for each binary; runtime must verify against this manifest.

---

## 🚀 Runtime Responsibilities
1. Load service manifest, verify each binary's hash and permission bits before launch.
2. Supervise services as subprocesses, streaming logs and rotating them.
3. Expose HTTP control plane:
   - `GET /status` – overall health summary
   - `POST /restart/{service}` – restart one service
   - `POST /shutdown` – graceful stop of all services
4. Periodically call each service's health endpoint and restart on failure.
5. Provide scheduled maintenance hooks (certificate renewal, cache purge, database migrations).

---

## 🔐 Security Constraints
- Embed a compile‑time guard in every service binary that validates the launcher signature; if missing, the binary exits.
- Secrets are injected only by the launcher at runtime; services may not read `.env` directly.
- Refuse to launch if any hash or env check fails.
- No Docker, `systemd`, or external process managers.

---

## 📦 File Layout
```
FountainAiLauncher/
├── Package.swift
├── Sources/
│   ├── Diagnostics/
│   ├── Builder/
│   ├── Installer/
│   ├── Supervisor/
│   └── ControlPlane/
└── Tests/
```

---

## ✅ Completion Checklist
- [ ] Replace `scripts/boot.sh` with equivalent Swift modules.
- [ ] Build + install pipeline implemented.
- [ ] Service manifest with hashes and permission checks.
- [ ] Runtime supervisor with HTTP control plane.
- [ ] Golden-key self-check embedded in all services.
- [ ] Unit tests covering build pipeline and supervisor restart logic.
- [ ] README describes `swift run FountainAiLauncher` as the one-click boot command.

---

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
