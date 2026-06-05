import SwiftUI

@main
struct RhythmForgeApp: App {
    @StateObject private var midiEngine  = MIDIEngineViewModel()
    @StateObject private var piano       = PianoViewModel()
    @StateObject private var sequencer   = SequencerViewModel()
    @StateObject private var devices     = DevicesViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(midiEngine)
                .environmentObject(piano)
                .environmentObject(sequencer)
                .environmentObject(devices)
                .onAppear {
                    midiEngine.setup()
                    piano.connect(to: midiEngine)
                    sequencer.connect(to: midiEngine)
                    devices.connect(to: midiEngine)
                }
        }
    }
}
