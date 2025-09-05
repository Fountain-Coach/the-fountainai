# OpenAPI Curator — Architecture Blueprint (FountainAI)

## 1) Purpose & Scope
**Goal:** Produce a *curated*, conflict-free, safe subset of FountainAI’s ecosystem OpenAPIs before they are submitted to **Tools Factory**.  
**Non-goals:** runtime auth/rate-limiting (Gateway concern), tool execution (Tool Server concern).

---

## 2) High-Level Flow

1. **Ingest** one or more OpenAPI 3.0/3.1 specs (YAML/JSON, files or URLs).
2. **Normalize** (parse, deref `$ref`, ensure consistent schema).
3. **Curate**
   - Filter **denylisted** endpoints (admin/sensitive/internal).
   - Enforce **allowlist** and **tag/path rules** per service.
   - Resolve **operationId collisions** (namespacing/renaming or exclusion).
   - Validate **parameter schemas** and **security** hints.
4. **Diff** against prior curated snapshot (optional “review gate”).
5. **Emit** a single curated spec + report.
6. **(Optional) Submit** curated spec to Tools Factory `/tools/register`.

---

## 3) Service Shape

- Service name: `openapi-curator-service`
- Port: `8000` (internal, consistent with FountainAI standard)
- Config via root `.env` (no hardcoded URLs):
  - `TOOLS_FACTORY_URL`
  - `CURATOR_RULES_PATH` (default: `Configuration/curator.yml`)
  - `CURATOR_STORAGE_PATH` (e.g., `/data/corpora/<corpusId>/curator/`)
  - `DEFAULT_CORPUS_ID` (e.g., `tools-factory`)
- Persists artifacts into the **corpus** file tree:
  - `/data/corpora/<corpusId>/curator/YYYYMMDD-HHMM/curated.yaml`
  - `/data/corpora/<corpusId>/curator/YYYYMMDD-HHMM/report.json`

---

## 4) Minimal OpenAPI (Curator’s API)

```
openapi: 3.1.0
info:
  title: OpenAPI Curator Service
  version: 0.1.0
paths:
  /curate:
    post:
      summary: Curate one or more OpenAPI documents
      operationId: curate
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                corpusId: { type: string }
                specs:
                  type: array
                  items:
                    oneOf:
                      - type: object  # inline OpenAPI object
                        additionalProperties: true
                      - type: string  # URL or repo path
                submitToToolsFactory: { type: boolean, default: false }
              required: [specs]
      responses:
        "200":
          description: Curated spec and report
          content:
            application/json:
              schema:
                type: object
                properties:
                  curatedOpenAPI: { type: object, additionalProperties: true }
                  report:
                    type: object
                    properties:
                      removed: { type: array, items: { type: string } }
                      renamed:
                        type: array
                        items:
                          type: object
                          properties: { from: {type: string}, to: {type: string} }
                      collisions:
                        type: array
                        items:
                          type: object
                          properties:
                            operationId: { type: string }
                            services: { type: array, items: { type: string } }
                      warnings: { type: array, items: { type: string } }
  /validate:
    post:
      summary: Validate specs without curating
      operationId: validate
      requestBody: { ... }
      responses: { "200": { description: "Validation report" } }
  /rules:
    get:
      summary: Get active curation rules
      operationId: get_rules
      responses: { "200": { description: "Rules YAML as JSON" } }
    put:
      summary: Replace curation rules
      operationId: put_rules
      requestBody: { ... }
      responses: { "204": { description: "Rules replaced" } }
  /history:
    get:
      summary: List curated snapshots for a corpus
      operationId: history
      parameters:
        - in: query
          name: corpusId
          schema: { type: string }
      responses: { "200": { description: "List of snapshots" } }
```

---

## 5) Curation Rule Model (DSL)

Place at `Configuration/curator.yml` (hot-reload on SIGHUP or `PUT /rules`).

```yaml
# Which services’ specs we source
sources:
  - id: baseline-awareness
    allow_urls:
      - file://openapi/v1/baseline-awareness.yml
  - id: tools-factory
    allow_urls:
      - file://openapi/v1/tools-factory.yml

# Global exclusions (paths or tags apply across all sources)
global:
  deny:
    tags: [admin, internal, experimental]
    paths:
      - ^/metrics$
      - ^/roleguard
      - ^/awareness/experimental
    operationIds: [metrics_metrics_get, register_openapi]  # avoid recursion

# Per-source overrides (more precise control)
per_source:
  baseline-awareness:
    allow:
      tags: [public, client]
    deny:
      paths: [^/awareness/internal, ^/debug]
  tools-factory:
    deny:
      operationIds: [register_openapi, list_tools]  # do not expose as tools

# OperationId policy
operationId:
  strategy: namespace_if_conflict   # options: fail_on_conflict | drop_on_conflict | namespace_if_conflict
  namespace_format: "{sourceId}_{operationId}"  # used when conflicts detected

# Safety guards
safety:
  require_security_schemes: false   # if true, only include ops with security
  deny_unsafe_methods_on_public: [DELETE, PUT, PATCH]  # unless allowlisted
```

---

## 6) Collision & Filtering Algorithm (pseudocode)

```text
inputs: specs[], rules, corpusId
S := []   # collected operations
R := { removed:[], renamed:[], collisions:[], warnings:[] }

for each spec in specs:
  doc := load_and_normalize(spec)    # JSON/YAML -> JSON, resolve refs if feasible
  srcId := infer_source_id(spec)
  for (path, methods) in doc.paths:
    for (method, op) in methods:
      if not method in [GET,POST,PUT,PATCH,DELETE]: continue
      opId := op.operationId or make_op_id(path, method)

      # global/per-source deny checks
      if matches_global_or_per_source_deny(op, path, opId, srcId): 
        R.removed += f"{srcId}:{opId}"
        continue

      # allow checks (if configured)
      if uses_allowlists and not is_allowed(op, path, srcId):
        R.removed += f"{srcId}:{opId}"
        continue

      # collision handling
      if exists S with operationId == opId:
        if rules.operationId.strategy == "fail_on_conflict":
          R.collisions += { operationId: opId, services: [existing.srcId, srcId] }
          continue
        if rules.operationId.strategy == "drop_on_conflict":
          R.removed += f"{srcId}:{opId}"
          continue
        if rules.operationId.strategy == "namespace_if_conflict":
          newId := format(rules.operationId.namespace_format, srcId, opId)
          R.renamed += { from: opId, to: newId }
          opId := newId

      # safety
      if unsafe_public_combo(op, method, path, rules):
        R.removed += f"{srcId}:{opId}"
        continue

      # accept
      S += { srcId, path, method, opId, summary, description, tags }

# build curated OpenAPI with operations S
curated := openapi_skeleton()
for s in S: curated.paths[s.path][s.method.toLower()] = build_op(s)

return { curatedOpenAPI: curated, report: R }
```

---

## 7) Integration with Tools Factory

* **Dry-run**: default; return curated spec + report only.
* **Submit**: when `submitToToolsFactory=true`, `POST curated spec` to `${TOOLS_FACTORY_URL}/tools/register?corpusId=<id>` (idempotent at TF layer).
* **Safe defaults**:

  * Never include `register_openapi` or `list_tools` from the Tools Factory spec (avoid recursion).
  * Deny `/metrics` endpoints by default.
  * Namespace on collision (`{sourceId}_{operationId}`) to preserve both tools when needed.

---

## 8) Storage & Observability

* **Artifacts**: Store both curated output and report under the corpus, timestamped.
* **Metrics** (expose `/metrics` for scrape):

  * `curator_ops_total{action="kept|removed|renamed"}`
  * `curator_collisions_total`
  * `curator_submit_total{status="success|error"}`
  * `curator_rules_version` (hash of rules content)

---

## 9) Security Model

* Curator runs in the internal network.
* If submission is enabled, use a service token (JWT) for posting to Tools Factory.
* When fronted by the Gateway, use the **RoleGuard** plugin to restrict access:
  * `/curate` requires the `curator:write` role.
  * `/rules` (GET/PUT) requires the elevated `curator:admin` role.
* **No** exposure of curated admin endpoints as tools by default.

---

## 10) Dev & Deploy

> **Status:** The Curator is an internal **build-time/tooling component**. It must **not** become a hard deployment dependency. It should run locally, in CI, or as an ad-hoc service, producing artifacts that other services (e.g., Tools Factory, Function Caller) can consume later.

**Form factors (choose any, mix & match):**
- **CLI tool** (`openapi-curator-cli`): single binary invoked by developers or CI to read specs, apply rules, and write curated outputs.  
- **Ephemeral service** (`openapi-curator-service` on port `8000`): start/stop on demand during integration tests or manual reviews; exposes the API defined in §4.  
- **Library module** (`OpenAPICuratorKit`): callable from other FountainAI build tools (e.g., codegen) without a network hop.

**Configuration (no hardcoded URLs):**
- All values are read from the root `.env` or process env at runtime:
  - `TOOLS_FACTORY_URL` (optional; only used when `submitToToolsFactory=true`)
  - `CURATOR_RULES_PATH` (default: `Configuration/curator.yml`)
  - `CURATOR_STORAGE_PATH` (default: `/data/corpora/<corpusId>/curator/`)
  - `DEFAULT_CORPUS_ID` (default: `tools-factory`)

**Execution modes:**
- **Review mode (default):** Run curation, write curated spec + report, return JSON; **do not** submit.  
- **Promotion mode (explicit):** Same as review, then POST curated spec to Tools Factory `/tools/register?corpusId=<id>`.

**Artifacts & contracts:**
- Outputs are **pure artifacts** under the corpus tree:
  - Curated spec: `/data/corpora/<corpusId>/curator/<timestamp>/curated.yaml`
  - Report: `/data/corpora/<corpusId>/curator/<timestamp>/report.json`
- These artifacts are the **only contract** other services rely on; consumers must not assume the Curator is running.

**Observability & health (when run as a service):**
- `/_health` for liveness.
- `/metrics` for counters (`curator_ops_total{kept|removed|renamed}`, `curator_collisions_total`, `curator_rules_version`, `curator_submit_total{status}`).

**Security posture:**
- If run behind the Gateway, wire `/curate` and `/rules` through the RoleGuard plugin so only callers with `curator:write` and `curator:admin` roles (respectively) pass; if run standalone, keep it on internal networks and require a service token for promotion mode.
- The Curator must always **strip** `/metrics` and self-referential TF ops (`register_openapi`, `list_tools`) before submission.

**Pipeline guidance (non-binding):**
- Use the CLI or service in **pre-deploy** steps to generate curated artifacts.
- Downstream deployment stages **consume artifacts only**; they must not fail if the Curator is not present at runtime.

**Non-goals for this section:**
- No mandate on a specific supervisor/launcher or hosting target.
- No coupling to a particular dispatcher/runner.


## 11) Test Strategy

* **Unit**: rule matching, collision resolver, namespace formatter.
* **Spec fixtures**: small OpenAPIs that purposely collide (`metrics_metrics_get`, `addBaseline`, etc.).
* **Golden files**: curated output snapshots.
* **Contract**: mock Tools Factory and assert the function list matches curated ops.
* **Performance**: large spec merge (hundreds of ops) within bounded time.

---

## 12) Quickstart Examples

### A) Minimal curation call (dry run)

```json
POST /curate
{
  "corpusId": "tools-factory",
  "specs": [
    "file://openapi/v1/baseline-awareness.yml",
    "file://openapi/v1/persist.yml",
    "file://openapi/v1/tools-factory.yml"
  ],
  "submitToToolsFactory": false
}
```

**Outcome:** `curatedOpenAPI` without `/metrics`, without TF’s `register_openapi`/`list_tools`, and with collision-safe `operationId`s.

### B) Promote curated spec to Tools Factory

```json
POST /curate
{
  "corpusId": "tools-factory",
  "specs": ["file:///data/corpora/tools-factory/curator/20250829-1012/curated.yaml"],
  "submitToToolsFactory": true
}
```

---

## 13) Roadmap Enhancements

* **`x-fountain.*` vendor extensions** in service specs to hint curation:

  * `x-fountain.visibility: public|internal`
  * `x-fountain.reason: "..."`
  * `x-fountain.allow-as-tool: true|false`
* **Policy packs** per environment (dev/stage/prod).
* **Schema-aware parameter extraction** to generate structured tool parameter schemas (optional).
* **UI** for diff/review of curated vs. original.

---

## 14) Acceptance Criteria

* Given overlapping ecosystem specs, running `/curate`:

  * **removes** denylisted/admin endpoints,
  * **resolves** all `operationId` conflicts per configured strategy,
  * **emits** a valid OpenAPI 3.1 document,
  * optionally **submits** to Tools Factory,
  * **persists** artifacts and **exposes** metrics.


