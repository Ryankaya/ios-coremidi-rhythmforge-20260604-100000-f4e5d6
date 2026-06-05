import SwiftUI

struct TransportView: View {
    @EnvironmentObject var sequencer: SequencerViewModel

    var body: some View {
        VStack(spacing: 14) {
            // BPM display
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(Int(sequencer.bpm))")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.cyan)
                Text("BPM")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
                // Tap tempo area — doubles as current-step indicator
                stepIndicators
            }

            // BPM slider
            HStack(spacing: 12) {
                Text("40")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $sequencer.bpm, in: 40...240, step: 1)
                    .tint(.cyan)
                    .onChange(of: sequencer.bpm) { sequencer.setBPM($0) }
                Text("240")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Transport buttons
            HStack(spacing: 20) {
                Button { sequencer.resetPattern() } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()

                Button { sequencer.togglePlayPause() } label: {
                    Image(systemName: sequencer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(sequencer.isPlaying ? .orange : .cyan)
                        .scaleEffect(sequencer.isPlaying ? 1.05 : 1)
                    .animation(.spring(response: 0.3), value: sequencer.isPlaying)
                }
            }
        }
        .foregroundStyle(.white)
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // 16 mini step indicators showing current playhead
    private var stepIndicators: some View {
        HStack(spacing: 2) {
            ForEach(0..<16) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i == sequencer.currentStep && sequencer.isPlaying
                          ? Color.cyan
                          : Color.white.opacity(i % 4 == 0 ? 0.25 : 0.1))
                    .frame(width: 8, height: i % 4 == 0 ? 16 : 10)
                    .animation(.easeOut(duration: 0.05), value: sequencer.currentStep)
            }
        }
    }
}
