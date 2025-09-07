# Teatro View Engine

![Swift](https://img.shields.io/badge/Swift-6.1-orange) ![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen)
*A Declarative, Codex-Controllable Rendering Framework in Swift*

Teatro is centered on **MIDI 2.0** for sequencing and timing. MIDI 1.0 is supported only as a fallback for legacy export.

## Render API

The `TeatroRenderAPI` module exposes deterministic rendering helpers and a SwiftUI `TeatroPlayerView` for quick previews. See [Docs/RenderAPI.md](Docs/RenderAPI.md) for usage examples.

## MIDI-CI Discovery

Teatro includes basic support for the MIDI Capability Inquiry (MIDI-CI) protocol.
`MIDICI` types generate SysEx packets for discovery, profile negotiation and
property exchange. These packets can be encoded with `UMPEncoder` and parsed
from `UMPParser` output using `MIDICIDispatcher` to obtain strongly typed
messages for application workflows.

## MIDI 1.0 Bridge

`MIDI1Bridge` converts between Universal MIDI Packets and traditional MIDI 1.0
byte streams. This makes it possible to route UMP data to legacy devices or
perform round‑trip tests.

```bash
swift run RenderCLI song.ump --midi1-bridge > song.midi
```

The command above reads a UMP file, translates it to MIDI 1.0 bytes, and writes
the result to standard output (or the file specified with `--output`).
`MIDI1Bridge.midi1ToUMP(_:)` performs the inverse conversion when needed.

## SSE over MIDI 2.0

Teatro can ingest **Server-Sent Events** streamed inside MIDI 2.0 UMP. Flex Data carries short envelopes while SysEx8 handles larger payloads. Streams honor JR Timestamps with a small jitter buffer so live tokens stay beat‑aligned. The player shows reliability stats and tokens in real time. A minimal capture lives at `assets/sse-demo.ump`.

### Command-line Playback

Pipe bridged MIDI data into the `teatro-play` utility to hear it through
FluidSynth on Linux or the Apple sampler on macOS:

```bash
swift run RenderCLI song.ump --midi1-bridge | \
    swift run teatro-play --from-stdin --sink fluidsynth --sf2 ./GeneralUser.sf2
```

The long-form documentation lives under `Docs/Chapters`. Start with the timeline and progress through each chapter.

## Documentation

- [Render API](Docs/RenderAPI.md)
- [1. Core Protocols](Docs/Chapters/01_CoreProtocols.md)
- [2. View Types](Docs/Chapters/02_ViewTypes.md)
- [3. Rendering Backends](Docs/Chapters/03_RenderingBackends.md)
- [4. CLI Integration](Docs/Chapters/04_CLIIntegration.md)
- [5. Animation System](Docs/Chapters/05_AnimationSystem.md)
- [6. LilyPond Music Rendering](Docs/Chapters/06_LilyPondMusicRendering.md)
- [7. MIDI 2.0 DSL](Docs/Chapters/07_MIDI20DSL.md)
- [8. Fountain Screenplay Engine](Docs/Chapters/08_FountainScreenplayEngine.md)
- [9. Fountain Parser Implementation](Docs/Chapters/09_FountainParserImplementationPlan.md)
- [10. Storyboard DSL](Docs/Chapters/10_StoryboardDSL.md)
- [11. TeatroPlayerView Usage](Docs/Chapters/11_TeatroPlayer.md)
- [12. SSE over MIDI 2.0](Docs/Chapters/12_SSE_Over_MIDI2.md)
- [13. TeatroSampler](Docs/Chapters/12_TeatroSampler.md)
- [Addendum: Apple Platform Compatibility](Docs/Chapters/Addendum.md)

Historical proposals live in [`Docs/Proposals`](Docs/Proposals).

## Continuous Integration

A GitHub Actions workflow runs [SwiftLint](.swiftlint.yml) and `swift test` on every push and pull request to ensure code quality and style consistency.

## Installation
Add the package to your `Package.swift` dependencies:
```swift
.package(url: "https://github.com/fountain-coach/teatro.git", branch: "main")
```
Then include `Teatro` as a dependency in your target.

````text
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
````
