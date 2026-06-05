import SwiftUI

struct PianoView: View {
    @EnvironmentObject var piano:    PianoViewModel
    @EnvironmentObject var engine:   MIDIEngineViewModel

    // Key geometry
    private let whiteKeyWidth:  CGFloat = 44
    private let whiteKeyHeight: CGFloat = 180
    private let blackKeyWidth:  CGFloat = 28
    private let blackKeyHeight: CGFloat = 110

    // Black key X offsets within a 7-white-key octave block (in fraction of white key width)
    private let blackKeyOffsets: [Int: CGFloat] = [
        1: 0.6,   // C#
        3: 1.6,   // D#
        6: 3.6,   // F#
        8: 4.6,   // G#
        10: 5.6   // A#
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.08).ignoresSafeArea()

                VStack(spacing: 16) {
                    headerCard
                    velocityRow
                    ScrollView(.horizontal, showsIndicators: false) {
                        keyboardCanvas
                            .padding(.horizontal, 8)
                    }
                    controlsRow
                    Spacer()
                }
                .padding(.top, 8)
            }
            .navigationTitle("Piano")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(white: 0.1), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Octave")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Button { piano.shiftOctave(by: -1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .disabled(piano.octaveOffset <= -2)

                    Text("C\(3 + piano.octaveOffset)")
                        .font(.title2.bold())
                        .foregroundStyle(.cyan)
                        .frame(width: 40)

                    Button { piano.shiftOctave(by: 1) } label: {
                        Image(systemName: "chevron.right")
                            .font(.title3.bold())
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .disabled(piano.octaveOffset >= 2)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Active notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(engine.activeNotes.count)")
                    .font(.largeTitle.bold())
                    .foregroundStyle(engine.activeNotes.isEmpty ? Color.secondary : Color.cyan)
            }
        }
        .foregroundStyle(.white)
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Velocity row

    private var velocityRow: some View {
        HStack(spacing: 12) {
            Text("Velocity")
                .font(.caption)
                .foregroundStyle(.secondary)
            Slider(value: Binding(
                get: { Double(piano.velocity) },
                set: { piano.velocity = UInt8(Int($0)) }
            ), in: 1...127, step: 1)
            .tint(.cyan)
            Text("\(piano.velocity)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.cyan)
                .frame(width: 28)
        }
        .foregroundStyle(.white)
        .padding(.horizontal)
    }

    // MARK: - Keyboard

    private var keyboardCanvas: some View {
        let startNote = piano.startNote
        let keys      = MIDIConstants.pianoKeyCount
        let notes     = (0..<keys).map { UInt8($0) + startNote }
        let whites    = notes.filter { !MIDIConstants.isBlackKey($0) }
        let totalW    = CGFloat(whites.count) * whiteKeyWidth

        return ZStack(alignment: .topLeading) {
            // White keys
            HStack(spacing: 1) {
                ForEach(whites, id: \.self) { pitch in
                    PianoKeyView(
                        pitch:      pitch,
                        isBlack:    false,
                        isPressed:  piano.pressedPitches.contains(pitch),
                        isExternal: engine.activeNotes.contains(pitch) && !piano.pressedPitches.contains(pitch),
                        onDown: { piano.keyDown(pitch: pitch) },
                        onUp:   { piano.keyUp(pitch: pitch) }
                    )
                    .frame(width: whiteKeyWidth, height: whiteKeyHeight)
                }
            }

            // Black keys overlaid
            blackKeysLayer(notes: notes, whites: whites, totalW: totalW)
        }
        .frame(width: totalW, height: whiteKeyHeight)
    }

    private func blackKeysLayer(notes: [UInt8], whites: [UInt8], totalW: CGFloat) -> some View {
        ForEach(notes.filter { MIDIConstants.isBlackKey($0) }, id: \.self) { pitch in
            let xOffset = blackKeyXOffset(for: pitch, whites: whites)
            PianoKeyView(
                pitch:      pitch,
                isBlack:    true,
                isPressed:  piano.pressedPitches.contains(pitch),
                isExternal: engine.activeNotes.contains(pitch) && !piano.pressedPitches.contains(pitch),
                onDown: { piano.keyDown(pitch: pitch) },
                onUp:   { piano.keyUp(pitch: pitch) }
            )
            .frame(width: blackKeyWidth, height: blackKeyHeight)
            .offset(x: xOffset)
        }
    }

    private func blackKeyXOffset(for pitch: UInt8, whites: [UInt8]) -> CGFloat {
        // Find the white key to the left
        let prevWhite = pitch - 1
        guard let whiteIndex = whites.firstIndex(of: prevWhite) else { return 0 }
        let noteInOctave = Int(pitch) % 12
        let fraction = blackKeyOffsets[noteInOctave] ?? 0.5
        return CGFloat(whiteIndex) * (whiteKeyWidth + 1) + fraction * whiteKeyWidth - blackKeyWidth * 0.5
    }

    // MARK: - Controls

    private var controlsRow: some View {
        HStack(spacing: 16) {
            // Sustain pedal
            Button {
                piano.setSustain(!piano.sustainOn)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: piano.sustainOn ? "pedal.fill" : "pedal")
                    Text("Sustain")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(piano.sustainOn ? .black : .cyan)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(piano.sustainOn ? Color.cyan : Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            Button {
                engine.allNotesOff()
                piano.pressedPitches.removeAll()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "stop.circle")
                    Text("All Off")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
    }
}
