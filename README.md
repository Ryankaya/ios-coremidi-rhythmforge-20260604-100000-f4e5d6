# RhythmForge — CoreMIDI Piano & Step Sequencer

A production-quality iOS app demonstrating the **CoreMIDI** framework through a real-time MIDI piano keyboard, 16-step pattern sequencer, device browser, and MIDI message monitor.

## Feature Highlights

### Piano Tab
- 3-octave scrollable keyboard (C3–C6, 37 keys) with black/white key touch detection
- Octave shift (–2 to +2)
- Per-key velocity control
- Sustain pedal (sends CC64 to all destinations)
- Keys light cyan when you press them; light green when an external MIDI device triggers them
- All Notes Off panic button

### Sequencer Tab
- 16-step × 4-track pattern sequencer (Kick / Snare / Hi-Hat / Synth)
- BPM range 40–240 with live slider; timer restarts on BPM change
- Default house beat pre-loaded
- Per-track: mute, clear, randomize (configurable density)
- Animated step playhead indicator

### Devices Tab
- Live enumeration of every CoreMIDI source and destination using `MIDIGetNumberOfSources/Destinations`
- Displays device name, manufacturer, model (via `MIDIObjectGetStringProperty`)
- Shows the two virtual endpoints this app advertises to other apps
- Online/offline status dot; pull-to-refresh toolbar button

### Monitor Tab
- Real-time log of every incoming and outgoing MIDI packet
- Colour-coded: blue = incoming, green = outgoing, orange = system events
- Filterable by direction and free-text search
- Auto-capped at 200 entries; clear button

## CoreMIDI APIs Demonstrated

| API | Purpose |
|-----|---------|
| `MIDIClientCreateWithBlock` | Create client with device plug/unplug notification callback |
| `MIDIOutputPortCreate` | Send MIDI bytes to external hardware/apps |
| `MIDIInputPortCreateWithBlock` | Receive MIDI from connected external sources |
| `MIDISourceCreate` | Virtual source — other apps subscribe and receive our output |
| `MIDIDestinationCreateWithBlock` | Virtual destination — other apps send MIDI to us |
| `MIDIGetNumberOfSources / Destinations` | Enumerate the MIDI device graph |
| `MIDIObjectGetStringProperty` | Read `kMIDIPropertyName`, `kMIDIPropertyManufacturer`, `kMIDIPropertyModel` |
| `MIDIObjectGetIntegerProperty` | Read `kMIDIPropertyOffline` for online/offline status |
| `MIDIPortConnectSource` | Subscribe input port to an external source |
| `MIDISend` | Transmit a `MIDIPacketList` to an external destination |
| `MIDIReceived` | Notify our virtual source of outgoing data |
| `MIDIPacketNext` | Iterate packets within a `MIDIPacketList` |

## Apple Documentation

- [CoreMIDI Framework Reference](https://developer.apple.com/documentation/coremidi)
- [MIDIClientCreate and MIDI Setup Notifications](https://developer.apple.com/documentation/coremidi/1495360-midiclientcreatewithblock)
- [AVAudioUnitSampler — built-in General MIDI synthesis](https://developer.apple.com/documentation/avfaudio/avaudiounitsampler)
- [AVAudioEngine — audio graph management](https://developer.apple.com/documentation/avfaudio/avaudioengine)

## Architecture

Strict MVVM with `@MainActor` isolation:

```
Models (value types, Codable)
├── MIDIConstants.swift    — note names, frequencies, status bytes, GM drum map
├── MIDIDevice.swift       — endpoint model with Kind enum
└── SequencerModels.swift  — SequencerStep, SequencerTrack, MIDILogEntry

ViewModels (ObservableObject, @MainActor)
├── MIDIEngineViewModel    — CoreMIDI client, ports, virtual endpoints, AVAudioUnitSampler
├── PianoViewModel         — key press state, sustain, octave shift
├── SequencerViewModel     — pattern, BPM, Combine-based clock, transport
└── DevicesViewModel       — device enumeration, refreshed on MIDI notifications

Views (SwiftUI, no business logic)
├── Piano/     PianoView, PianoKeyView
├── Sequencer/ SequencerView, TransportView, StepButton
├── Devices/   DevicesView
└── Monitor/   MonitorView
```

## Requirements

- iOS 16.2+
- Xcode 15+
- Generated with XcodeGen (`xcodegen generate`)

## Build

```bash
xcodegen generate
open RhythmForge.xcodeproj
```

Run on a **physical device** for the best experience — the system General MIDI soundbank and real MIDI hardware connections are only available on device. The simulator still demonstrates all CoreMIDI API calls and the virtual endpoints appear in other MIDI-capable apps running on the same Mac.
