# MIDI2 Swift Library

Swift 6 library for building and parsing **MIDI 2.0 Universal MIDI
Packets (UMP)**. The package is generated from the normative JSON Schema and
OpenAPI definitions and now provides full MIDI 2.0 spec coverage, including core UMP structures, SysEx7/SysEx8
streaming utilities, MIDI‑CI envelope helpers, and a teaching‑oriented
`midi2demo` CLI for experimenting with the specification.

## Status

The library implements the entire MIDI 2.0 specification and now ships with the `TeatroAppleBridge` Core MIDI adapter, accompanying command-line demos, and unit tests. Version 0.3.0 is ready for consumption via Swift Package Manager. The `midi2demo` CLI covers all subcommands—`note-on`, `sysex7`, `sysex8`, `flex` (tempo, time signature, key, lyric), `ci-handshake`, and `inspect`—with validation for edge cases and options to simulate MIDI-CI failures. A `midi2demo.1` man page and enhanced `--help` output accompany the tool. Integration tests spawn the `midi2demo` executable to exercise success and failure paths for every subcommand. The `jitterdemo` sample now builds with Swift 6.1 strict concurrency and actor data race checks.

## Features

- Complete MIDI 2.0 specification coverage with binary encoder/decoder.
- SysEx7 and SysEx8 streaming helpers.
- MIDI‑CI envelope support.
- Teaching‑oriented `midi2demo` CLI.
- [API documentation](midi2.full.openapi.json).
- Examples and XCTest test suite.

## Roadmap

- Track spec updates and maintain conformance.
- Expand the `midi2demo` CLI with additional streaming, Flex Data, and packet inspection commands.
- Harden the codebase with additional documentation and integration tests.

## Installation

Add `MIDI2` to your project using the [Swift Package Manager](https://www.swift.org/package-manager/):

```swift
dependencies: [
    .package(url: "https://example.com/midi2.git", from: "0.3.0")
]
```

Then import the library:

```swift
import MIDI2
```

### Upgrading

To upgrade from an earlier release, update the version in your package manifest and run:

```bash
swift package update MIDI2
```

## midi2demo CLI

Build and run the teaching-oriented CLI to experiment with MIDI 2.0 messages.
Examples:

```bash
swift run midi2demo note-on --group 0 --channel 0 60 100
swift run midi2demo sysex7 --group 0 --manufacturer 7D "01 02 03"
swift run midi2demo sysex8 --group 0 --manufacturer 00,20,33 "01 02 03 04"
swift run midi2demo flex tempo --group 0 120
swift run midi2demo flex time --group 0 4 4
swift run midi2demo flex key --group 0 C#m
swift run midi2demo flex lyric --group 0 "Hello world"
swift run midi2demo ci-handshake --no-common-protocol --unsupported-profile --missing-property
swift run midi2demo inspect 0x40107D00 0x00640000
```

Each command prints the encoded Universal MIDI Packet and decodes it back to
human-readable fields.

### Man page

Install the man page:

```bash
sudo install -m 0644 Sources/midi2demo/midi2demo.1 /usr/local/share/man/man1/
man midi2demo
```

### CLI tests

Run the CLI tests with SwiftPM:

```bash
swift test --filter midi2demo
```

### Code Coverage

Generate a coverage report using the Swift toolchain's `llvm-cov` to avoid
profile format mismatches:

```bash
swift test --enable-code-coverage
LLVM_COV="$(dirname $(dirname $(which swift)))/usr/bin/llvm-cov"
$LLVM_COV report .build/x86_64-unknown-linux-gnu/debug/MIDI2PackageTests.xctest \
  --instr-profile .build/x86_64-unknown-linux-gnu/debug/codecov/default.profdata
```

## TeatroAppleBridge (Core MIDI adapter)

`TeatroAppleBridge` is a small package that bridges the library's Universal MIDI
Packet model to Apple's Core MIDI and MusicSequence APIs. It exposes
`AppleMIDIBridge` for sending or publishing UMP, `AppleMIDIReceiver` for
receiving via a handler block, and `AppleSequencerBridge` for offline sequence
export.

### Demos

The `Examples/` folder contains command-line demos:

- `SendCCDemo` – send CC ramps and a note burst to a destination.
- `VirtualSourceDemo` – publish a virtual source and echo incoming events.
- `SequenceExportDemo` – build a sequence and write a `.mid` file.

## Jitter Reduction

MIDI 2.0 introduces Jitter Reduction (JR) Clock and Timestamp messages to
preserve precise scheduling over links that may introduce transmission
variation. The library exposes these as `Utility.jrClock` and
`Utility.jrTimestamp`, which encode 16‑bit values representing a sender’s
timebase and per‑message offsets for jitter‑corrected playback.

Run the demo executable to observe the packets and their reconstructed times:

```bash
swift run jitterdemo
```

For background on the JR mechanism, see the MIDI 2.0 Universal MIDI Packet
specification (Section 4, “Jitter Reduction (JR) Clock and Timestamps”) in
`M2-104-UM_v1-1-2_UMP_and_MIDI_2-0_Protocol_Specification.pdf`.

## Examples

See the `Examples/` directory for Swift Playgrounds demonstrating common tasks:

- [Basic usage](Examples/BasicUsage.playground)
- [Streaming SysEx7 data](Examples/SysEx7.playground)
- [Streaming SysEx8 data](Examples/SysEx8.playground)
- [Mixed Data Set chunk transfer](Examples/MDS.playground)
- [Flex tempo message](Examples/FlexTiming.playground)
- [MIDI-CI handshake](Examples/MIDICIHandshake.playground)

CLI demos built with `TeatroAppleBridge`:

- [SendCCDemo](Examples/SendCCDemo)
- [VirtualSourceDemo](Examples/VirtualSourceDemo)
- [SequenceExportDemo](Examples/SequenceExportDemo)

### Encoding a Channel Voice Message

```swift
import MIDI2

let group = Uint4(0)!
let channel = Uint4(0)!
let control = Uint7(64)!
let message = ControlChange(group: group, channel: channel, control: control, value: 0x7F)
let ump = message.ump()
```

### Streaming SysEx7 Data

```swift
import MIDI2

let payload: [UInt8] = [0x7D, 0x01, 0x02]
let packets = try SysEx7.fragment(manufacturerID: [0x7D], payload: payload)
```

