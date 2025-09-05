# How do I install FountainAI locally?

FountainAI bundles a convenience script that boots the entire stack and its in-memory FountainStore for quick experiments.

## Quick start

1. Clone the repository and enter it.
2. Run the starter:
   ```bash
   ./scripts/start-local.sh
   ```
   The script checks `.env`, prompts for any missing variables, then calls the standard boot process.
3. When prompted, supply:
   - `FOUNTAINSTORE_URL` – use `http://localhost:8005` for the embedded store.
   - `FOUNTAINSTORE_API_KEY` – any string (e.g. `local-dev`).
   - `OPENAI_API_KEY` – your real OpenAI key.
4. After the build completes the Gateway service exposes the API, typically on port `8010`.

## Using a standalone FountainStore

To persist data between runs, deploy a real FountainStore service and point FountainAI at it:

1. Start the external FountainStore and note its HTTPS endpoint and API key.
2. Export those values before launching:
   ```bash
   export FOUNTAINSTORE_URL=https://store.example.com
   export FOUNTAINSTORE_API_KEY=long-secret-value
   ```
3. Run `./scripts/start-local.sh` (or the `FountainAiLauncher` binary) and the stack will use the external store instead of the embedded one.

For background on the store itself, see [What is the FountainStore?](./what-is-the-fountainstore.md).

