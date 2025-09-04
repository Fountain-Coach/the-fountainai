# Services

Each service in this directory follows a common layout:

- `README.md` referencing the service's canonical OpenAPI specification.
- `openapi/` containing symlinks to the spec stored under the repository's top-level `openapi/` directory.
- Source files (e.g., `main.swift`).

When adding a new service:

1. Add or update the spec under `openapi/v{major}/`.
2. Create an `openapi/` subfolder in the service directory.
3. Symlink the spec into the subfolder, e.g.:
   ```bash
   ln -s ../../../openapi/v1/my-service.yml services/MyService/openapi/my-service.yml
   ```
4. Reference the spec from the service's `README.md`.

This keeps service implementations and their OpenAPI contracts discoverable and consistently organized.
