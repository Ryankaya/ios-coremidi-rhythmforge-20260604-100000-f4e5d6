import SwiftUI

struct SequencerView: View {
    @EnvironmentObject var sequencer: SequencerViewModel
    @State private var selectedTrack: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.08).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        TransportView()

                        // Step grid for each track
                        ForEach(sequencer.tracks.indices, id: \.self) { trackIndex in
                            TrackRowView(
                                track:      $sequencer.tracks[trackIndex],
                                trackIndex: trackIndex,
                                currentStep: sequencer.currentStep,
                                isPlaying:   sequencer.isPlaying
                            )
                        }

                        // Track controls for selected track
                        trackActionsView

                        Spacer(minLength: 24)
                    }
                    .padding()
                }
            }
            .navigationTitle("Sequencer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(white: 0.1), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var trackActionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Track Actions")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(sequencer.tracks.indices, id: \.self) { i in
                    Button {
                        selectedTrack = i
                    } label: {
                        Text(sequencer.tracks[i].name)
                            .font(.caption.bold())
                            .foregroundStyle(selectedTrack == i ? .black : sequencer.tracks[i].color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTrack == i
                                ? sequencer.tracks[i].color
                                : sequencer.tracks[i].color.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    sequencer.clearTrack(trackIndex: selectedTrack)
                } label: {
                    Label("Clear", systemImage: "trash")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    sequencer.randomize(trackIndex: selectedTrack, density: 0.35)
                } label: {
                    Label("Random", systemImage: "dice")
                        .font(.subheadline)
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Spacer()

                Toggle("Mute", isOn: Binding(
                    get: { sequencer.tracks[selectedTrack].isMuted },
                    set: { _ in sequencer.toggleMute(trackIndex: selectedTrack) }
                ))
                .tint(.orange)
                .font(.subheadline)
                .foregroundStyle(.white)
                .labelsHidden()
                Text("Mute")
                    .font(.subheadline)
                    .foregroundStyle(sequencer.tracks[selectedTrack].isMuted ? .orange : .secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Track row with 16 step buttons

struct TrackRowView: View {
    @Binding var track: SequencerTrack
    let trackIndex:     Int
    let currentStep:    Int
    let isPlaying:      Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(track.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(track.isMuted ? .secondary : track.color)
                Text(MIDIConstants.noteName(for: track.pitch))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("ch:\(track.channel + 1)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Step buttons in two groups of 8 (beat groups)
            VStack(spacing: 4) {
                stepRow(range: 0..<8)
                stepRow(range: 8..<16)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(track.isMuted ? Color.gray.opacity(0.2) : track.color.opacity(0.3), lineWidth: 1)
        )
    }

    private func stepRow(range: Range<Int>) -> some View {
        HStack(spacing: 4) {
            ForEach(range, id: \.self) { stepIndex in
                StepButton(
                    isActive:   track.steps[stepIndex].isActive,
                    isCurrent:  isPlaying && stepIndex == currentStep,
                    isFirstBeat: stepIndex % 4 == 0,
                    color:      track.color,
                    isMuted:    track.isMuted
                )
                .onTapGesture {
                    track.steps[stepIndex].isActive.toggle()
                }
            }
        }
    }
}

struct StepButton: View {
    let isActive:    Bool
    let isCurrent:   Bool
    let isFirstBeat: Bool
    let color:       Color
    let isMuted:     Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(strokeColor, lineWidth: isCurrent ? 2 : 1)
            )
            .frame(height: 36)
            .scaleEffect(isCurrent && isActive ? 1.08 : 1)
            .animation(.spring(response: 0.1), value: isCurrent)
    }

    private var fillColor: Color {
        if isCurrent && isActive { return color }
        if isCurrent             { return Color.white.opacity(0.25) }
        if isActive && isMuted   { return color.opacity(0.25) }
        if isActive              { return color.opacity(0.7) }
        if isFirstBeat           { return Color.white.opacity(0.08) }
        return Color.white.opacity(0.04)
    }

    private var strokeColor: Color {
        if isCurrent { return .cyan }
        if isActive  { return color.opacity(0.5) }
        return Color.white.opacity(0.08)
    }
}
