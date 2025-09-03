# Tools Factory Quick Start

This service registers tools (functions) from an OpenAPI document and lists them from FountainStore.

## Run the service

```bash
export FOUNTAINSTORE_URL=http://localhost:8108
export FOUNTAINSTORE_API_KEY=fs_api_key
# optional corpus id (defaults to tools-factory)
export TOOLS_FACTORY_CORPUS_ID=my-corpus

swift run tools-factory-server
```

## Register tools from OpenAPI

```bash
curl -sS -X POST \
  -H 'Content-Type: application/json' \
  'http://localhost:8080/tools/register?corpusId=my-corpus' \
  --data-binary @openapi/v1/tools-factory.yml | jq .
```

Any operationId under `paths` becomes a registered function with `{function_id, name, description, http_method, http_path}`.

## List registered tools

```bash
curl -sS 'http://localhost:8080/tools?page=1&page_size=20' | jq .
```

## Invoke a tool (adapter)

Adapters are available at `POST /{tool}` for configured tools in `tools.json`. For example:

```bash
curl -sS -X POST \
  -H 'Content-Type: application/json' \
  'http://localhost:8080/ffmpeg' \
  --data '{"args":["-h"],"request_id":"demo-1"}'
```

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

