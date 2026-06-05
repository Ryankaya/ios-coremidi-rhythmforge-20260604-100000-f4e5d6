import SwiftUI

struct ContentView: View {
    @EnvironmentObject var midiEngine: MIDIEngineViewModel

    var body: some View {
        TabView {
            PianoView()
                .tabItem { Label("Piano", systemImage: "pianokeys") }

            SequencerView()
                .tabItem { Label("Sequencer", systemImage: "music.note.list") }

            DevicesView()
                .tabItem { Label("Devices", systemImage: "cable.connector.horizontal") }

            MonitorView()
                .tabItem { Label("Monitor", systemImage: "waveform") }
        }
        .tint(.cyan)
    }
}
