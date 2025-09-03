# 🧠 FountainAI Root Agent — **FountainStore Integration (Corpus-First Rule)**

_Last updated: 03.09.2025_

## 0) Scope & Intent
Codex, your task is to **implement FountainStore as the sole persistence layer**, remodeled around the **corpus** as the basic unit. Every persisted object must live under a corpus, and each corpus is modeled via the **Bootstrapping** and **Baseline Awareness** OpenAPIs. Remove legacy indexer semantics, including the evolved Typesense-like API. Persistence must reflect semantic memory as designed in Bootstrapping + Baseline Awareness.

This file is the **canonical manifest** at the repo root that Codex follows when improving the repository. Keep it up-to-date and machine-actionable.

---

## 1) Golden Rule
> **Everything is persisted under a corpus.**  
> All FountainAI services write/read through FountainStore into a corpus tree. The corpus structure is authoritative and defined by Bootstrapping and Baseline Awareness. No dual APIs, no detached indexers, no semantic browser persistence outside the semantic memory engine.

---

## 2) Deliverables (this PR series)

### 2.1 Specs & Text Updates
- Purge all references to external or evolved indexer APIs.  
- Update Semantic Browser spec to say: **“Artifacts are persisted into FountainStore under a corpus.”**  
- Ensure Bootstrapping and Baseline Awareness OpenAPIs are referenced as the definitional model for corpus creation, readiness, and baseline anchoring.

### 2.2 FountainStore Client (Swift)
Implement `libs/FountainStoreClient` with corpus-first methods:
- `createCorpus(id, metadata)`
- `getCorpus(id)`
- `deleteCorpus(id)`
- `putDoc(corpusId, collection, id, body)`
- `getDoc(corpusId, collection, id)`
- `deleteDoc(corpusId, collection, id)`
- `query(corpusId, collection, Query { byId|byIndexEq|prefixScan|filters|sort|limit|offset })`
- `capabilities()`
- `snapshot(corpusId)/restore(corpusId)`
- `backup(corpusId)/compaction(corpusId)`

### 2.3 Service Wiring
- **Semantic Browser**: when `/v1/browse` runs with `index.enabled=true`, it must write artifacts into the correct **corpus** inside FountainStore. The corpus context must be obtained from Bootstrapping + Baseline Awareness.  
- **Launcher/ops**: require corpus-aware environment wiring (`FOUNTAINSTORE_URL`, `FOUNTAINSTORE_API_KEY`). Entry points still route through the Launcher as the golden key.

### 2.4 Collections (per corpus)
Within each corpus, create collections:
1) `pages`  
2) `segments`  
3) `entities`  
4) `tables`  
5) `analyses`

All under `/corpora/{corpusId}/collections/{name}`.

---

## 3) Capability Negotiation (Ask-for-More)
Expose and consume neutral corpus-aware capability surface:

**FountainStore** must serve:
```http
GET /v1/capabilities
→ {
  "corpus": true,
  "documents": ["upsert","get","delete"],
  "query": ["byId","byIndexEq","prefixScan","filters","sort"],
  "transactions": ["snapshot","restore"],
  "admin": ["health","backup","compaction","metrics"],
  "experimental": []
}
```

**Clients**:
1. Resolve corpus context via Bootstrapping + Baseline Awareness.  
2. Call `/v1/capabilities` on startup.  
3. If a requested op isn’t present, return `400 NotSupported` upstream with `"need": "query.fullText"` (example), log a **capability request**, and fall back.

---

## 4) Query Model (Phase-1)
Supported query shapes inside a corpus:
- **byId**
- **byIndexEq**
- **prefixScan**
- Boolean **filters**, `limit/offset`, `sort`

No other query shapes are guaranteed. Advanced features require capability negotiation.

---

## 5) Configuration & Security
Environment variables:
```
FOUNTAINSTORE_URL
FOUNTAINSTORE_API_KEY
```
- Health at `/v1/health`.  
- Prometheus metrics at `/metrics`.  
- All access must resolve a corpus context first.  
- Launcher remains the **golden key** and links to this file.

---

## 6) Migration (Populate FountainStore)
One-shot ingest job:
- For each Bootstrapped corpus, replay Semantic Browser exports (pages/segments/entities/tables/analyses) into the corpus-aware FountainStore structure.  
- No residual indexer pathways remain.

---

## 7) Tests & CI (Lean by Default)
Follow the **Ultra-Lean Root Agent Directive**:
- **Tier-A (default)**: build only impacted targets; run only unit + contract tests for those; finish under ~5 minutes; print one summary block.  
- **Tier-B**: escalate if contracts / public APIs / corpus model changed.

**Minimum coverage**:
- Unit tests for `FountainStoreClient` corpus methods.  
- Semantic Browser corpus indexing path tests.  
- Capability fallback tests (NotSupported → degrade & log).  

---

## 8) Acceptance Checklist
- [ ] All Typesense/Evolved indexer APIs removed.  
- [ ] Corpus-first persistence rules applied.  
- [ ] Semantic Browser writes to corpus collections only.  
- [ ] Bootstrapping + Baseline Awareness OpenAPIs integrated as corpus model.  
- [ ] `/v1/capabilities` consumed; requests logged.  
- [ ] Lean CI (Tier-A) green.  
- [ ] Launcher/ops docs list `FOUNTAINSTORE_*` env and reference corpus model.

---

## 9) Output Format
At the end of every Codex run, print:

```json
{
  "mode": "Tier-A | Tier-B",
  "impactedTargets": ["..."],
  "build": "passed | failed",
  "tests": "passed | failed",
  "durations": {"buildSec": 0, "testsSec": 0},
  "capabilityRequests": [{"need": "query.fullText", "count": 3}]
}
```

---

## 10) Placement
This file **lives at the repository root** as `agent.md` and is the canonical contract for Codex-driven repository improvement.

---

```
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
```
