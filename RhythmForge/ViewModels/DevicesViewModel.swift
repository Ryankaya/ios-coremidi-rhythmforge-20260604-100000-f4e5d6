import Foundation
import CoreMIDI
import Combine

// Reads the CoreMIDI device graph and presents sources + destinations as MIDIDevice models.
@MainActor
final class DevicesViewModel: ObservableObject {

    @Published var sources:      [MIDIDevice] = []
    @Published var destinations: [MIDIDevice] = []

    private var cancellables = Set<AnyCancellable>()
    private weak var engine: MIDIEngineViewModel?

    func connect(to engine: MIDIEngineViewModel) {
        self.engine = engine
        refresh()

        NotificationCenter.default
            .publisher(for: .midiDevicesChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
    }

    // MARK: - Device enumeration

    func refresh() {
        sources      = enumerateSources()
        destinations = enumerateDestinations()
    }

    private func enumerateSources() -> [MIDIDevice] {
        let count = MIDIGetNumberOfSources()
        return (0..<count).compactMap { i in
            let endpoint = MIDIGetSource(i)
            guard endpoint != 0 else { return nil }
            let isVirtual = (endpoint == engine?.virtualSourceRef)
            return MIDIDevice(
                name:        getString(endpoint, kMIDIPropertyName)        ?? "Unknown",
                manufacturer: getString(endpoint, kMIDIPropertyManufacturer) ?? "",
                model:        getString(endpoint, kMIDIPropertyModel)         ?? "",
                endpointRef: endpoint,
                kind:        isVirtual ? .virtualSource : .source,
                isOnline:    getInteger(endpoint, kMIDIPropertyOffline) == 0
            )
        }
    }

    private func enumerateDestinations() -> [MIDIDevice] {
        let count = MIDIGetNumberOfDestinations()
        return (0..<count).compactMap { i in
            let endpoint = MIDIGetDestination(i)
            guard endpoint != 0 else { return nil }
            let isVirtual = (endpoint == engine?.virtualDestinationRef)
            return MIDIDevice(
                name:         getString(endpoint, kMIDIPropertyName)         ?? "Unknown",
                manufacturer: getString(endpoint, kMIDIPropertyManufacturer) ?? "",
                model:        getString(endpoint, kMIDIPropertyModel)         ?? "",
                endpointRef:  endpoint,
                kind:         isVirtual ? .virtualDestination : .destination,
                isOnline:     getInteger(endpoint, kMIDIPropertyOffline) == 0
            )
        }
    }

    // MARK: - CoreMIDI property helpers

    private func getString(_ endpoint: MIDIEndpointRef, _ key: CFString) -> String? {
        var value: Unmanaged<CFString>?
        guard MIDIObjectGetStringProperty(endpoint, key, &value) == noErr else { return nil }
        return value?.takeRetainedValue() as String?
    }

    private func getInteger(_ endpoint: MIDIEndpointRef, _ key: CFString) -> Int32 {
        var value: Int32 = 0
        MIDIObjectGetIntegerProperty(endpoint, key, &value)
        return value
    }

    // MARK: - Summary

    var totalDevices: Int { sources.count + destinations.count }

    var externalSources: [MIDIDevice] {
        sources.filter { $0.kind == .source }
    }
}
