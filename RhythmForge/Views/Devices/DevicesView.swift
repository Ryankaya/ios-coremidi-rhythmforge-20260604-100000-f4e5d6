import SwiftUI
import CoreMIDI

struct DevicesView: View {
    @EnvironmentObject var devicesVM: DevicesViewModel
    @EnvironmentObject var engine:    MIDIEngineViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.08).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        summaryCard
                        virtualEndpointsCard
                        if !devicesVM.externalSources.isEmpty || !devicesVM.destinations.filter({ $0.kind == .destination }).isEmpty {
                            externalDevicesCard
                        } else {
                            noExternalDevicesCard
                        }
                        midiInfoCard
                    }
                    .padding()
                }
            }
            .navigationTitle("MIDI Devices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(white: 0.1), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { devicesVM.refresh() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .tint(.cyan)
                }
            }
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        HStack(spacing: 0) {
            statCell(value: devicesVM.sources.count,      label: "Sources",      color: .blue)
            Divider().background(Color.white.opacity(0.1))
            statCell(value: devicesVM.destinations.count, label: "Destinations", color: .green)
            Divider().background(Color.white.opacity(0.1))
            statCell(value: devicesVM.totalDevices,       label: "Total",        color: .cyan)
        }
        .frame(height: 72)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statCell(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.title.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Virtual endpoints (created by RhythmForge itself)

    private var virtualEndpointsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Virtual Endpoints", icon: "app.badge.checkmark")
            Text("Other apps can send MIDI to \"RhythmForge\" and receive MIDI from \"RhythmForge\".")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                endpointRow(
                    name:         "RhythmForge",
                    subtitle:     "Virtual Source — apps receive our output",
                    kind:         .virtualSource,
                    ref:          engine.virtualSourceRef
                )
                endpointRow(
                    name:         "RhythmForge",
                    subtitle:     "Virtual Destination — apps send us MIDI",
                    kind:         .virtualDestination,
                    ref:          engine.virtualDestinationRef
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - External devices

    private var externalDevicesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("External Devices", icon: "cable.connector.horizontal")

            let externalSrc  = devicesVM.sources.filter { $0.kind == .source }
            let externalDest = devicesVM.destinations.filter { $0.kind == .destination }

            if !externalSrc.isEmpty {
                Text("INPUTS").font(.caption2.bold()).foregroundStyle(.blue.opacity(0.7))
                ForEach(externalSrc) { device in deviceCard(device) }
            }
            if !externalDest.isEmpty {
                Text("OUTPUTS").font(.caption2.bold()).foregroundStyle(.green.opacity(0.7))
                ForEach(externalDest) { device in deviceCard(device) }
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var noExternalDevicesCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "cable.connector.slash")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No External MIDI Devices")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Connect a USB MIDI interface, MIDI controller, or use a MIDI-capable app to see devices here.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Info

    private var midiInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("CoreMIDI APIs Used", icon: "info.circle")

            let apis: [(String, String)] = [
                ("MIDIClientCreateWithBlock", "Client with notification callback"),
                ("MIDIOutputPortCreate",       "Send MIDI to external destinations"),
                ("MIDIInputPortCreateWithBlock","Receive from external sources"),
                ("MIDISourceCreate",           "Virtual source (apps see our output)"),
                ("MIDIDestinationCreateWithBlock","Virtual destination (apps send to us)"),
                ("MIDIGetNumberOfSources/Destinations","Enumerate endpoints"),
                ("MIDIObjectGetStringProperty", "Read device name/manufacturer/model"),
                ("MIDIPortConnectSource",       "Subscribe to external MIDI sources"),
                ("MIDISend / MIDIReceived",     "Send packets to external / virtual")
            ]

            ForEach(apis, id: \.0) { api, desc in
                HStack(alignment: .top, spacing: 8) {
                    Text(api)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.cyan)
                    Text("–")
                        .foregroundStyle(.secondary)
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.bold())
            .foregroundStyle(.white)
    }

    private func endpointRow(name: String, subtitle: String, kind: MIDIDevice.Kind, ref: MIDIEndpointRef) -> some View {
        HStack(spacing: 12) {
            Image(systemName: kind.sfSymbol)
                .font(.title3)
                .foregroundStyle(kind.tintColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline.bold()).foregroundStyle(.white)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Text("ref:\(ref)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func deviceCard(_ device: MIDIDevice) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(device.kind.tintColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: device.kind.sfSymbol)
                    .foregroundStyle(device.kind.tintColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                if !device.manufacturer.isEmpty || !device.model.isEmpty {
                    Text([device.manufacturer, device.model].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Circle()
                .fill(device.isOnline ? Color.green : Color.red)
                .frame(width: 8, height: 8)
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
