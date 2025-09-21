# Environment (shared)

FountainAiLauncher is the single source of truth for runtime configuration. Start it via the CLI wrapper or the macOS Launcher UI so it can sign subprocesses and inject credentials on your behalf:

```bash
bash Scripts/launcher start
```

Use the Launcher's **Environment** tab (GUI) or the control-plane status view at `http://127.0.0.1:9090/status` to confirm the following values are present before exercising a module:

- `FOUNTAINSTORE_URL` — base URL for the FountainStore API
- `FOUNTAINSTORE_API_KEY` — API key/token for FountainStore
- `FOUNTAIN_GATEWAY_URL` — base URL for the LLM/Gateway facade
- `PLANNER_URL` — base URL for Planner service
- `AWARENESS_URL` — base URL for Baseline Awareness service
- `TOOLS_FACTORY_URL` — base URL for the Tools Factory service
- `FUNCTION_CALLER_URL` — base URL for the Function Caller service
- `TEATRO_BASE_URL` — (if the GUI is served separately)

> Do **not** `source .env` or export credentials globally. Keep secrets inside the Launcher so every service inherits the same signed environment and nothing leaks into your shell.
