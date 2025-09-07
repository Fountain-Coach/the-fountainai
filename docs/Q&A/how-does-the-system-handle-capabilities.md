# How does the system handle capabilities?

FountainAI advertises and enforces feature support through a capabilities mechanism:

- **Capability exposure** – Services such as the persistence layer expose a `GET /capabilities` endpoint defined in their OpenAPI contract. It returns a serialized `Capabilities` object listing feature groups (corpus, documents, querying, transactions, administrative tasks, and experimental flags).
- **Negotiation and enforcement** – Clients fetch capabilities at startup, cache them, and check for required features before performing operations. Missing capabilities increment telemetry counters and raise `PersistenceError.notSupported` with the specific requirement.
- **Telemetry and UI integration** – Capability requests are aggregated for visibility. The GUI roadmap and publishing frontend rely on `/v1/capabilities` endpoints to adapt interfaces and surface `NotSupported` errors to users.

This coordination ensures that each service declares supported operations, clients guard against unsupported calls, and UIs can adjust to the available feature set.

See also [What is the FountainStore?](./what-is-the-fountainstore.md).
