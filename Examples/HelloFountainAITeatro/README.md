# HelloFountainAITeatro

Minimal macOS SwiftUI example for rendering a message with **Teatro** after
calling the FountainAI Semantic Browser health endpoint.

## Build & Run (macOS)

```bash
swift run HelloFountainAITeatro
```

The app requests `GET http://localhost:8007/v1/health` and renders the response
status inside a Teatro scene.
