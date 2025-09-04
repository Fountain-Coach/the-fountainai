# What is the FountainStore?

The **FountainStore** is FountainAI's persistence layer. It provides a
multi-corpus, document-oriented store for every semantic artifact the
platform generates.

- **Corpora as namespaces** – each corpus groups related data. Documents
  are stored under `/corpora/{corpusId}/collections/{name}`.
- **Typed collections** – standard collections like `pages`, `segments`,
  `entities`, `tables`, and `analyses` organize the data structure (see
  [FountainStore corpus collections](../fountainstore-collections.md)).
- **RESTful access** – the `PersistServer` exposes an API for creating
  corpora, upserting documents, querying, and administering snapshots or
  backups. The OpenAPI specification lives at
  [openapi/v1/persist.yml](../../openapi/v1/persist.yml).
- **Capability negotiation** – clients use `FountainStoreClient` to learn
  which features (query modes, transactions, admin operations) the
  underlying store supports.

Together these pieces give FountainAI durable storage and retrieval of
pages, segments, and other semantic artifacts across its services.
