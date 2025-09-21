# Environment (shared)

Define these environment variables in your preferred method (dotenv, Xcode scheme, or runtime flags):

- `FOUNTAINSTORE_URL` — base URL for the FountainStore API
- `FOUNTAINSTORE_API_KEY` — API key/token for FountainStore
- `FOUNTAIN_GATEWAY_URL` — base URL for the LLM/Gateway facade
- `PLANNER_URL` — base URL for Planner service
- `AWARENESS_URL` — base URL for Baseline Awareness service
- `TOOLS_FACTORY_URL` — base URL for the Tools Factory service
- `FUNCTION_CALLER_URL` — base URL for the Function Caller service
- `TEATRO_BASE_URL` — (if the GUI is served separately)

> All reads/writes must go through HTTP APIs. No direct DB/filesystem access from GUI.
