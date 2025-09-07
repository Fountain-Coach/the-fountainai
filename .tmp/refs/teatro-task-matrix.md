# 📋 Task Matrix

| Feature | File(s) or Area | Action | Status | Blockers | Tags |
|--------|-----------------|--------|--------|----------|------|
| Replace deprecated `Process.launchPath` | Sources/ViewCore/LilyScore.swift | Switch to `executableURL` and update process launch | ⏳ | None | cli, refactor |
| Update deprecated file-loading calls | Sources/Audio/CsoundSampler.swift | Use `String(contentsOf:encoding:)` across codebase | ⏳ | None | refactor, test |
| Increase renderer test coverage | Tests/RendererTests.swift and related | Add cases for HTML/Markdown and image rendering | ⏳ | Need sample fixtures | renderer, test |
| Sync CLI docs with current flags | Docs/Chapters/04_CLIIntegration.md; Sources/CLI/RenderCLI.swift | Ensure documentation matches implemented options | ⚠️ | Manual verification | docs, cli |
| Automate coverage report updates | COVERAGE.md; scripts | Add script/CI step to refresh coverage metrics | ❌ | Decide tooling | ci, coverage |
