import SwiftUI

struct MonitorView: View {
    @EnvironmentObject var engine: MIDIEngineViewModel
    @State private var filterText = ""
    @State private var showIncoming  = true
    @State private var showOutgoing  = true
    @State private var showSystem    = true

    private var filteredLog: [MIDILogEntry] {
        engine.midiLog.filter { entry in
            let dirOK: Bool
            switch entry.direction {
            case .incoming: dirOK = showIncoming
            case .outgoing: dirOK = showOutgoing
            case .system:   dirOK = showSystem
            }
            if filterText.isEmpty { return dirOK }
            return dirOK && entry.message.localizedCaseInsensitiveContains(filterText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.08).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter chips
                    filterBar
                        .padding()

                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Filter messages…", text: $filterText)
                            .foregroundStyle(.white)
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    if filteredLog.isEmpty {
                        Spacer()
                        emptyState
                        Spacer()
                    } else {
                        List(filteredLog) { entry in
                            logRow(entry)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("MIDI Monitor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(white: 0.1), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear") { engine.midiLog.removeAll() }
                        .tint(.red)
                }
            }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            filterChip("In",     color: .blue,   isOn: $showIncoming, icon: "arrow.down.circle.fill")
            filterChip("Out",    color: .green,  isOn: $showOutgoing, icon: "arrow.up.circle.fill")
            filterChip("System", color: .orange, isOn: $showSystem,   icon: "gearshape.fill")
            Spacer()
            Text("\(filteredLog.count) msgs")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func filterChip(_ label: String, color: Color, isOn: Binding<Bool>, icon: String) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption2)
                Text(label).font(.caption.bold())
            }
            .foregroundStyle(isOn.wrappedValue ? .black : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isOn.wrappedValue ? color : color.opacity(0.12))
            .clipShape(Capsule())
        }
    }

    private func logRow(_ entry: MIDILogEntry) -> some View {
        HStack(spacing: 10) {
            Image(systemName: entry.icon)
                .font(.caption2)
                .foregroundStyle(entry.color)
                .frame(width: 16)

            Text(entry.timeString)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 86, alignment: .leading)

            Text(entry.message)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No MIDI messages yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Play piano keys or start the sequencer to see messages appear here in real time.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
