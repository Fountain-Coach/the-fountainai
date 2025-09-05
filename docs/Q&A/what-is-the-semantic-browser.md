# What is the Semantic Browser?

The Semantic Browser is a Swift service that renders a web page, captures a DOM and network snapshot, performs light semantic dissection, and can persist the derived artifacts into FountainStore under a corpus. It is built to be pragmatic, vendor‑neutral, and production‑ready.

Key capabilities include:

- **Snapshot** – capture `snapshot.html` and normalized `snapshot.text` with URL, status, content type, and timing metadata.
- **Analyze** – segment the rendered text into headings, paragraphs, code, and tables while extracting entities with stable spans.
- **Browse** – perform snapshot and analysis in one call with optional indexing of artifacts.
- **Index and Query** – store pages, segments, entities, and tables in [FountainStore](what-is-the-fountainstore.md) and retrieve them later.
- **Export and Admin** – stream stored artifacts and inspect health or metrics for observability and maintenance.

By turning raw web content into structured, corpus‑aware data, the Semantic Browser enables FountainAI to reason over and reuse web pages across its services.
