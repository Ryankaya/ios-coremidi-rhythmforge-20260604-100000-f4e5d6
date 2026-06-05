import Foundation
import Combine

@MainActor
final class PianoViewModel: ObservableObject {

    @Published var octaveOffset: Int  = 0      // -2 … +2
    @Published var velocity:     UInt8 = 100
    @Published var sustainOn:    Bool  = false

    // Notes held down by the player (without octave shift applied, just raw UI key index)
    @Published var pressedPitches: Set<UInt8> = []

    private weak var engine: MIDIEngineViewModel?
    private var sustainedNotes: Set<UInt8> = []

    func connect(to engine: MIDIEngineViewModel) { self.engine = engine }

    // MARK: - Computed

    var startNote: UInt8 {
        let base = Int(MIDIConstants.pianoStartNote) + octaveOffset * 12
        return UInt8(clamping: base)
    }

    // MARK: - Key interactions

    func keyDown(pitch: UInt8) {
        guard !pressedPitches.contains(pitch) else { return }
        pressedPitches.insert(pitch)
        engine?.noteOn(pitch: pitch, velocity: velocity)
    }

    func keyUp(pitch: UInt8) {
        pressedPitches.remove(pitch)
        if sustainOn {
            sustainedNotes.insert(pitch)
        } else {
            engine?.noteOff(pitch: pitch)
        }
    }

    func setSustain(_ on: Bool) {
        sustainOn = on
        engine?.sendControlChange(MIDIConstants.cc_sustain, value: on ? 127 : 0)
        if !on {
            for pitch in sustainedNotes where !pressedPitches.contains(pitch) {
                engine?.noteOff(pitch: pitch)
            }
            sustainedNotes.removeAll()
        }
    }

    func shiftOctave(by delta: Int) {
        engine?.allNotesOff()
        pressedPitches.removeAll()
        sustainedNotes.removeAll()
        octaveOffset = max(-2, min(2, octaveOffset + delta))
    }
}
