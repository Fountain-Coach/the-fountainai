#!/usr/bin/env python3
"""Replay Semantic Browser exports into FountainStore for all Bootstrapped corpora."""

from __future__ import annotations
import os
import json
from pathlib import Path
from typing import Iterable

import requests

BOOTSTRAP_URL = os.environ.get("BOOTSTRAP_URL")
FOUNTAINSTORE_URL = os.environ.get("FOUNTAINSTORE_URL")
FOUNTAINSTORE_API_KEY = os.environ.get("FOUNTAINSTORE_API_KEY", "")
EXPORT_ROOT = Path(os.environ.get("SEMANTIC_BROWSER_EXPORTS", "exports"))

REQUIRED_ENV = {
    "BOOTSTRAP_URL": BOOTSTRAP_URL,
    "FOUNTAINSTORE_URL": FOUNTAINSTORE_URL,
}

missing = [name for name, val in REQUIRED_ENV.items() if not val]
if missing:
    raise SystemExit(f"missing required env vars: {', '.join(missing)}")


def list_bootstrapped_corpora() -> Iterable[str]:
    """Return iterable of corpus IDs from the Bootstrapping service.

    Expects the Bootstrap service to expose a `/corpora` endpoint returning::
        {"corpora": [{"corpusId": "abc"}, ...]}
    """
    resp = requests.get(f"{BOOTSTRAP_URL.rstrip('/')}/corpora")
    resp.raise_for_status()
    data = resp.json()
    for item in data.get("corpora", []):
        cid = item.get("corpusId")
        if cid:
            yield cid


def replay_corpus(corpus_id: str) -> None:
    """Replay Semantic Browser exports for a single corpus."""
    collections = ["pages", "segments", "entities", "tables", "analyses"]
    corpus_dir = EXPORT_ROOT / corpus_id
    headers = {
        "Authorization": f"Bearer {FOUNTAINSTORE_API_KEY}",
        "Content-Type": "application/json",
    }

    for collection in collections:
        path = corpus_dir / f"{collection}.jsonl"
        if not path.exists():
            continue
        with path.open() as f:
            for line in f:
                doc = json.loads(line)
                doc_id = doc.get("id")
                if not doc_id:
                    continue
                url = (
                    f"{FOUNTAINSTORE_URL.rstrip('/')}/corpora/{corpus_id}/"
                    f"collections/{collection}/documents/{doc_id}"
                )
                resp = requests.put(url, headers=headers, json=doc)
                resp.raise_for_status()
    print(f"Replayed corpus {corpus_id}")


def main() -> None:
    for corpus_id in list_bootstrapped_corpora():
        replay_corpus(corpus_id)


if __name__ == "__main__":
    main()
