# Tutor Path Docs Agent

This directory mirrors the [tutor v1.0.0](https://github.com/Fountain-Coach/tutor/releases/tag/v1.0.0) documentation pack. Keep the layout stable when updating:

- `README.md` provides the Tutor Path overview for this repository.
- `modules/` contains the numbered module walkthroughs.
- `_includes/` stores shared environment, testing, and repo link snippets.

## Editing guidelines
- Preserve the shared outline inside every module (**Outcome**, **What you’ll ship**, **Specs to read**, **Behavioral acceptance**, **Test plan**, **Runbook**, **Hand-off to Codex**).
- When cross-linking, use relative paths so the docs render correctly in local viewers.
- Reuse `_includes/` snippets rather than duplicating environment or testing guidance.
- Reference FountainAI specs via relative paths (e.g. `openapi/v1/...`).
- When adding modules, follow the numbering and kebab-case naming pattern (`NN-title`).

## Keeping parity with the upstream release
- Note the release version in `README.md` when updating the docs.
- If you pull changes from a future Tutor release, update the version annotation and summarize the differences in the commit message.
- Do not remove sections without replacing them with equivalent guidance—surface deltas as TODO callouts instead.
