import Foundation

enum MIDIConstants {
    static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    static func noteName(for pitch: UInt8) -> String {
        "\(noteNames[Int(pitch) % 12])\(Int(pitch) / 12 - 1)"
    }

    static func frequency(for pitch: UInt8) -> Double {
        440.0 * pow(2.0, (Double(pitch) - 69.0) / 12.0)
    }

    static func isBlackKey(_ pitch: UInt8) -> Bool {
        [1, 3, 6, 8, 10].contains(Int(pitch) % 12)
    }

    // Piano range: C3 (48) to C6 (84) — 37 keys
    static let pianoStartNote: UInt8 = 48
    static let pianoKeyCount: Int    = 37

    // MIDI status bytes (upper nibble)
    static let noteOff:         UInt8 = 0x80
    static let noteOn:          UInt8 = 0x90
    static let polyAftertouch:  UInt8 = 0xA0
    static let controlChange:   UInt8 = 0xB0
    static let programChange:   UInt8 = 0xC0
    static let channelPressure: UInt8 = 0xD0
    static let pitchBend:       UInt8 = 0xE0

    // General MIDI drum map (channel 10, index 9)
    static let kickDrum:      UInt8 = 36
    static let acousticSnare: UInt8 = 38
    static let closedHiHat:   UInt8 = 42
    static let openHiHat:     UInt8 = 46
    static let lowFloorTom:   UInt8 = 41
    static let crashCymbal:   UInt8 = 49
    static let rideCymbal:    UInt8 = 51

    // Control change numbers
    static let cc_modulation:   UInt8 = 1
    static let cc_volume:       UInt8 = 7
    static let cc_pan:          UInt8 = 10
    static let cc_sustain:      UInt8 = 64
    static let cc_allNotesOff:  UInt8 = 123
}
