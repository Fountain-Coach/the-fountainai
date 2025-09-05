# OpenAPI Curator

## Overview
The OpenAPI Curator filters FountainAI service specifications into a conflict-free subset before the Tools Factory sees them. It runs as a CLI for build scripts or as an ephemeral review service, emitting curated specs and reports for each run. For the high-level system design, see the [architecture blueprint](openapi-curator-architecture.md).

## API Examples
The service exposes endpoints such as `/curate`:

```http
POST /curate
Content-Type: application/json

{
  "corpusId": "tools-factory",
  "specs": ["file://openapi/v1/baseline-awareness.yml"],
  "submitToToolsFactory": false
}
```

It returns a JSON object containing `curatedOpenAPI` and a `report` with removed or renamed operations.

## CLI Usage
Run the CLI locally or in CI:

```bash
swift run openapi-curator-cli --spec openapi/v1/tools-factory.yml --corpus tools-factory
```

Add `--submit` to register the curated spec with the Tools Factory.

## Promotion Workflow
1. Run curation in review mode to produce `curated.yaml` and `report.json`.
2. Inspect the artifacts and diff against previous snapshots.
3. Rerun with `submitToToolsFactory=true` or `--submit` to promote the curated spec.

## Quickstart Examples
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

## Acceptance Criteria
* Given overlapping ecosystem specs, running `/curate`:
  * **removes** denylisted/admin endpoints,
  * **resolves** all `operationId` conflicts per configured strategy,
  * **emits** a valid OpenAPI 3.1 document,
  * optionally **submits** to Tools Factory,
  * **persists** artifacts and **exposes** metrics.
