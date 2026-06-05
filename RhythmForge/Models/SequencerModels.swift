import Foundation
import SwiftUI

struct SequencerStep: Identifiable, Codable, Equatable {
    var id       = UUID()
    var isActive: Bool   = false
    var velocity: UInt8  = 100
}

struct SequencerTrack: Identifiable, Codable {
    var id        = UUID()
    var name:      String
    var colorName: String
    var pitch:     UInt8
    var channel:   UInt8
    var isMuted:   Bool = false
    var steps:     [SequencerStep]

    var color: Color {
        switch colorName {
        case "red":    return .red
        case "orange": return .orange
        case "yellow": return Color(red: 0.95, green: 0.85, blue: 0)
        case "green":  return .green
        case "blue":   return .blue
        case "purple": return .purple
        case "pink":   return .pink
        case "teal":   return .teal
        default:       return .gray
        }
    }

    init(name: String, colorName: String, pitch: UInt8, channel: UInt8 = 9) {
        self.name      = name
        self.colorName = colorName
        self.pitch     = pitch
        self.channel   = channel
        self.steps     = Array(repeating: SequencerStep(), count: 16)
    }
}

struct MIDILogEntry: Identifiable {
    let id        = UUID()
    let timestamp = Date()
    let message:   String
    let direction: Direction

    enum Direction { case incoming, outgoing, system }

    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: timestamp)
    }

    var icon: String {
        switch direction {
        case .incoming: return "arrow.down.circle.fill"
        case .outgoing: return "arrow.up.circle.fill"
        case .system:   return "gearshape.fill"
        }
    }

    var color: Color {
        switch direction {
        case .incoming: return .blue
        case .outgoing: return .green
        case .system:   return .orange
        }
    }
}
