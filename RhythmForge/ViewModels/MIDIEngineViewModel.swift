import Foundation
import CoreMIDI
import AVFoundation
import Combine

// Central MIDI + audio engine. All CoreMIDI API calls are concentrated here.
@MainActor
final class MIDIEngineViewModel: ObservableObject {

    // MARK: - Published state

    @Published var isRunning         = false
    @Published var activeNotes:  Set<UInt8> = []
    @Published var midiLog:      [MIDILogEntry] = []
    @Published var errorMessage: String?

    // Endpoints created by this app — exposed so DevicesViewModel can list them
    private(set) var virtualSourceRef:      MIDIEndpointRef = 0
    private(set) var virtualDestinationRef: MIDIEndpointRef = 0

    // MARK: - CoreMIDI refs

    private var midiClient  = MIDIClientRef()
    private var inputPort   = MIDIPortRef()
    private var outputPort  = MIDIPortRef()

    // MARK: - Audio

    private let audioEngine = AVAudioEngine()
    private let sampler     = AVAudioUnitSampler()

    // MARK: - Setup

    func setup() {
        guard !isRunning else { return }
        setupAudio()
        setupMIDI()
        isRunning = true
        log("RhythmForge engine started", direction: .system)
    }

    // MARK: - Audio engine

    private func setupAudio() {
        audioEngine.attach(sampler)
        audioEngine.connect(sampler, to: audioEngine.mainMixerNode, format: nil)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try audioEngine.start()

            // Load system General MIDI DLS soundbank (available on physical devices)
            let dlsURL = URL(fileURLWithPath:
                "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
            if FileManager.default.fileExists(atPath: dlsURL.path) {
                try sampler.loadSoundBankInstrument(
                    at: dlsURL,
                    program: 0,
                    bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                    bankLSB: 0
                )
            }
        } catch {
            errorMessage = "Audio: \(error.localizedDescription)"
        }
    }

    // MARK: - CoreMIDI client + ports

    private func setupMIDI() {
        // 1. Create client with a notification block for device add/remove events
        var status = MIDIClientCreateWithBlock("RhythmForge" as CFString, &midiClient) { [weak self] notifPtr in
            self?.handleMIDISystemNotification(notifPtr)
        }
        guard status == noErr else {
            errorMessage = "MIDIClientCreate failed: \(status)"
            return
        }

        // 2. Output port — used to send MIDI to external destinations
        status = MIDIOutputPortCreate(midiClient, "RhythmForge Out" as CFString, &outputPort)
        if status != noErr { errorMessage = "Output port failed: \(status)" }

        // 3. Input port — receives MIDI from all connected sources
        status = MIDIInputPortCreateWithBlock(midiClient, "RhythmForge In" as CFString, &inputPort) { [weak self] packetListPtr, _ in
            self?.handleIncomingPackets(packetListPtr, isVirtual: false)
        }
        if status != noErr { errorMessage = "Input port failed: \(status)" }

        // 4. Virtual source — other apps on the same device can receive our MIDI output
        MIDISourceCreate(midiClient, "RhythmForge" as CFString, &virtualSourceRef)

        // 5. Virtual destination — other apps can send MIDI to us
        MIDIDestinationCreateWithBlock(midiClient, "RhythmForge" as CFString, &virtualDestinationRef) { [weak self] packetListPtr, _ in
            self?.handleIncomingPackets(packetListPtr, isVirtual: true)
        }

        // 6. Connect our input port to every currently-connected external source
        connectAllExternalSources()
    }

    // Connect input port to all external sources (skipping our own virtual source)
    private func connectAllExternalSources() {
        let count = MIDIGetNumberOfSources()
        for i in 0..<count {
            let src = MIDIGetSource(i)
            guard src != virtualSourceRef else { continue }
            MIDIPortConnectSource(inputPort, src, nil)
        }
    }

    // MARK: - System notification (device plug / unplug)

    // Called on a CoreMIDI high-priority thread — dispatch UI work to main actor
    private func handleMIDISystemNotification(_ notifPtr: UnsafePointer<MIDINotification>) {
        let msgID = notifPtr.pointee.messageID
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch msgID {
            case .msgObjectAdded:
                connectAllExternalSources()
                log("MIDI device connected", direction: .system)
                NotificationCenter.default.post(name: .midiDevicesChanged, object: nil)
            case .msgObjectRemoved:
                log("MIDI device disconnected", direction: .system)
                NotificationCenter.default.post(name: .midiDevicesChanged, object: nil)
            case .msgSetupChanged:
                connectAllExternalSources()
                NotificationCenter.default.post(name: .midiDevicesChanged, object: nil)
            default:
                break
            }
        }
    }

    // MARK: - Incoming packet handling

    // Called on CoreMIDI thread — safe to read packet data here then dispatch
    private func handleIncomingPackets(_ packetListPtr: UnsafePointer<MIDIPacketList>, isVirtual: Bool) {
        var messages: [(bytes: [UInt8], isVirtual: Bool)] = []
        let numPackets = Int(packetListPtr.pointee.numPackets)

        // Mutate through a mutable alias so MIDIPacketNext can do pointer arithmetic
        // on the real memory location (not a stack copy).
        let mutableListPtr = UnsafeMutablePointer(mutating: packetListPtr)
        withUnsafeMutablePointer(to: &mutableListPtr.pointee.packet) { firstPacket in
            var packet: UnsafeMutablePointer<MIDIPacket> = firstPacket
            for _ in 0..<numPackets {
                let length = Int(packet.pointee.length)
                if length > 0 {
                    let bytes = withUnsafeBytes(of: packet.pointee.data) {
                        Array($0.bindMemory(to: UInt8.self).prefix(min(length, 256)))
                    }
                    messages.append((bytes, isVirtual))
                }
                packet = MIDIPacketNext(packet)
            }
        }

        Task { @MainActor [weak self] in
            for msg in messages { self?.dispatchMIDIBytes(msg.bytes, isVirtual: msg.isVirtual) }
        }
    }

    private func dispatchMIDIBytes(_ bytes: [UInt8], isVirtual: Bool) {
        guard bytes.count >= 2 else { return }
        let statusType = bytes[0] & 0xF0
        let channel    = bytes[0] & 0x0F

        switch statusType {
        case MIDIConstants.noteOn where bytes.count >= 3 && bytes[2] > 0:
            let pitch = bytes[1]; let vel = bytes[2]
            activeNotes.insert(pitch)
            sampler.startNote(pitch, withVelocity: vel, onChannel: channel)
            log("NoteOn  \(MIDIConstants.noteName(for: pitch))  vel:\(vel)  ch:\(channel+1)", direction: .incoming)

        case MIDIConstants.noteOff,
             MIDIConstants.noteOn where bytes.count >= 3 && bytes[2] == 0:
            let pitch = bytes[1]
            activeNotes.remove(pitch)
            sampler.stopNote(pitch, onChannel: channel)
            log("NoteOff \(MIDIConstants.noteName(for: pitch))  ch:\(channel+1)", direction: .incoming)

        case MIDIConstants.controlChange where bytes.count >= 3:
            log("CC\(bytes[1])=\(bytes[2])  ch:\(channel+1)", direction: .incoming)

        case MIDIConstants.programChange where bytes.count >= 2:
            log("ProgramChange \(bytes[1])  ch:\(channel+1)", direction: .incoming)

        case MIDIConstants.pitchBend where bytes.count >= 3:
            let bend = Int(bytes[2]) << 7 | Int(bytes[1])
            log("PitchBend \(bend - 8192)  ch:\(channel+1)", direction: .incoming)

        default:
            break
        }
    }

    // MARK: - Note output (Piano / Sequencer → audio + MIDI routing)

    func noteOn(pitch: UInt8, velocity: UInt8 = 100, channel: UInt8 = 0) {
        activeNotes.insert(pitch)
        sampler.startNote(pitch, withVelocity: velocity, onChannel: channel)
        log("NoteOn  \(MIDIConstants.noteName(for: pitch))  vel:\(velocity)  ch:\(channel+1)", direction: .outgoing)
        routeOutgoing(bytes: [MIDIConstants.noteOn | channel, pitch, velocity])
    }

    func noteOff(pitch: UInt8, channel: UInt8 = 0) {
        activeNotes.remove(pitch)
        sampler.stopNote(pitch, onChannel: channel)
        log("NoteOff \(MIDIConstants.noteName(for: pitch))  ch:\(channel+1)", direction: .outgoing)
        routeOutgoing(bytes: [MIDIConstants.noteOff | channel, pitch, 0])
    }

    func sendControlChange(_ cc: UInt8, value: UInt8, channel: UInt8 = 0) {
        log("CC\(cc)=\(value)  ch:\(channel+1)", direction: .outgoing)
        routeOutgoing(bytes: [MIDIConstants.controlChange | channel, cc, value])
    }

    func allNotesOff() {
        for pitch in activeNotes { sampler.stopNote(pitch, onChannel: 0) }
        activeNotes.removeAll()
        routeOutgoing(bytes: [MIDIConstants.controlChange, MIDIConstants.cc_allNotesOff, 0])
    }

    // MARK: - MIDI routing helpers

    // Build a MIDIPacketList with one packet and send it to:
    //   • our virtual source (so external apps that subscribed to us receive it)
    //   • every external destination
    private func routeOutgoing(bytes: [UInt8]) {
        var packet = MIDIPacket()
        packet.timeStamp = 0
        packet.length    = UInt16(min(bytes.count, 256))
        withUnsafeMutableBytes(of: &packet.data) { dst in
            for (i, b) in bytes.prefix(256).enumerated() { dst[i] = b }
        }
        var packetList = MIDIPacketList(numPackets: 1, packet: packet)

        // Advertise on virtual source → external receivers see our output
        MIDIReceived(virtualSourceRef, &packetList)

        // Forward to all physical destinations
        let destCount = MIDIGetNumberOfDestinations()
        for i in 0..<destCount {
            let dest = MIDIGetDestination(i)
            guard dest != virtualDestinationRef else { continue }
            MIDISend(outputPort, dest, &packetList)
        }
    }

    // MARK: - Log

    private func log(_ message: String, direction: MIDILogEntry.Direction) {
        let entry = MIDILogEntry(message: message, direction: direction)
        midiLog.insert(entry, at: 0)
        if midiLog.count > 200 { midiLog.removeLast() }
    }
}

extension Notification.Name {
    static let midiDevicesChanged = Notification.Name("com.ryankaya.rhythmforge.midiDevicesChanged")
}
