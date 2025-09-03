# FountainStore Corpus Collections

All persisted artifacts live under `/corpora/{corpusId}/collections/{name}`.
The following collections are used across FountainAI services:

## pages
- `corpusId` – owning corpus
- `pageId` – unique page identifier
- `url` – canonical page URL
- `host` – host component of the URL
- `title` – page title

## segments
- `corpusId` – owning corpus
- `segmentId` – unique segment identifier
- `pageId` – parent page reference
- `kind` – semantic segment kind (e.g., paragraph, heading)
- `text` – segment content

## entities
- `corpusId` – owning corpus
- `entityId` – unique entity identifier
- `name` – entity surface form
- `type` – entity category label

## tables
- `corpusId` – owning corpus
- `tableId` – unique table identifier
- `pageId` – parent page reference
- `csv` – table serialized as CSV

## analyses
- `corpusId` – owning corpus
- `analysisId` – unique analysis identifier
- `pageId` – related page reference
- `summary` – short description of the analysis

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
