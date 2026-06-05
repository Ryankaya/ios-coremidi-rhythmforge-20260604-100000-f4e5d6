import Foundation
import Combine
import SwiftUI

@MainActor
final class SequencerViewModel: ObservableObject {

    // MARK: - Published

    @Published var tracks:       [SequencerTrack]
    @Published var bpm:          Double = 120
    @Published var isPlaying:    Bool   = false
    @Published var currentStep:  Int    = 0
    @Published var stepCount:    Int    = 16
    @Published var swing:        Double = 0    // 0…50 (%)

    // MARK: - Private

    private weak var engine: MIDIEngineViewModel?
    private var clockTimer:  AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.tracks = SequencerViewModel.defaultTracks()
    }

    // MARK: - Default pattern (house beat)

    static func defaultTracks() -> [SequencerTrack] {
        var kick  = SequencerTrack(name: "Kick",   colorName: "red",    pitch: MIDIConstants.kickDrum,      channel: 9)
        var snare = SequencerTrack(name: "Snare",  colorName: "orange", pitch: MIDIConstants.acousticSnare, channel: 9)
        var hat   = SequencerTrack(name: "Hi-Hat", colorName: "yellow", pitch: MIDIConstants.closedHiHat,   channel: 9)
        var synth = SequencerTrack(name: "Synth",  colorName: "purple", pitch: 60,                          channel: 0)

        // Kick on beats 1, 5, 9, 13
        [0, 4, 8, 12].forEach { kick.steps[$0].isActive = true }
        // Snare on beats 5, 13
        [4, 12].forEach { snare.steps[$0].isActive = true }
        // Hi-hat every 2nd step
        stride(from: 0, to: 16, by: 2).forEach { hat.steps[$0].isActive = true }
        // Simple synth melody
        [0, 3, 7, 10].forEach { synth.steps[$0].isActive = true }

        return [kick, snare, hat, synth]
    }

    // MARK: - Engine connection

    func connect(to engine: MIDIEngineViewModel) { self.engine = engine }

    // MARK: - Transport

    func play() {
        guard !isPlaying else { return }
        isPlaying   = true
        currentStep = 0
        scheduleTimer()
    }

    func stop() {
        isPlaying = false
        clockTimer?.cancel()
        clockTimer = nil
        engine?.allNotesOff()
        currentStep = 0
    }

    func togglePlayPause() {
        if isPlaying { stop() } else { play() }
    }

    // MARK: - Clock

    // Step duration: quarter note = 1 beat, 16th-note grid → bpm × 4 ticks/min
    private var stepIntervalSeconds: Double {
        60.0 / (bpm * 4.0)
    }

    private func scheduleTimer() {
        clockTimer?.cancel()
        let interval = stepIntervalSeconds
        clockTimer = Timer
            .publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        fireStep(currentStep)
        currentStep = (currentStep + 1) % stepCount

        // Re-schedule if BPM changed (Combine timer can't change interval live)
        // The timer interval is fixed at creation; check if it drifted.
    }

    private func fireStep(_ step: Int) {
        for track in tracks {
            guard !track.isMuted else { continue }
            let s = track.steps[step]
            guard s.isActive else { continue }
            engine?.noteOn(pitch: track.pitch, velocity: s.velocity, channel: track.channel)

            // Auto note-off after 80ms (staccato; enough for percussive sound)
            let pitch   = track.pitch
            let channel = track.channel
            Task {
                try? await Task.sleep(nanoseconds: 80_000_000)
                await MainActor.run { self.engine?.noteOff(pitch: pitch, channel: channel) }
            }
        }
    }

    // MARK: - BPM change restarts timer

    func setBPM(_ newBPM: Double) {
        bpm = max(40, min(240, newBPM))
        if isPlaying { scheduleTimer() }
    }

    // MARK: - Step editing

    func toggleStep(trackIndex: Int, stepIndex: Int) {
        tracks[trackIndex].steps[stepIndex].isActive.toggle()
    }

    func setVelocity(_ velocity: UInt8, trackIndex: Int, stepIndex: Int) {
        tracks[trackIndex].steps[stepIndex].velocity = velocity
    }

    func toggleMute(trackIndex: Int) {
        tracks[trackIndex].isMuted.toggle()
        if tracks[trackIndex].isMuted, let engine = engine {
            engine.noteOff(pitch: tracks[trackIndex].pitch, channel: tracks[trackIndex].channel)
        }
    }

    func clearTrack(trackIndex: Int) {
        for i in 0..<tracks[trackIndex].steps.count {
            tracks[trackIndex].steps[i].isActive = false
        }
    }

    func randomize(trackIndex: Int, density: Double = 0.4) {
        for i in 0..<tracks[trackIndex].steps.count {
            tracks[trackIndex].steps[i].isActive = Double.random(in: 0...1) < density
        }
    }

    func resetPattern() {
        stop()
        tracks = Self.defaultTracks()
    }
}
