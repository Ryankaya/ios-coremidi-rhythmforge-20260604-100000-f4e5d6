import Foundation
import CoreMIDI
import SwiftUI

struct MIDIDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    let manufacturer: String
    let model: String
    let endpointRef: MIDIEndpointRef
    let kind: Kind
    var isOnline: Bool

    enum Kind: String {
        case source             = "Input"
        case destination        = "Output"
        case virtualSource      = "Virtual In"
        case virtualDestination = "Virtual Out"

        var sfSymbol: String {
            switch self {
            case .source:             return "arrow.down.circle.fill"
            case .destination:        return "arrow.up.circle.fill"
            case .virtualSource:      return "arrow.down.circle"
            case .virtualDestination: return "arrow.up.circle"
            }
        }

        var tintColor: Color {
            switch self {
            case .source, .virtualSource:        return .blue
            case .destination, .virtualDestination: return .green
            }
        }

        var isInput: Bool { self == .source || self == .virtualSource }
    }

    init(name: String, manufacturer: String = "", model: String = "",
         endpointRef: MIDIEndpointRef, kind: Kind, isOnline: Bool = true) {
        self.id           = UUID()
        self.name         = name
        self.manufacturer = manufacturer
        self.model        = model
        self.endpointRef  = endpointRef
        self.kind         = kind
        self.isOnline     = isOnline
    }

    static func == (lhs: MIDIDevice, rhs: MIDIDevice) -> Bool {
        lhs.endpointRef == rhs.endpointRef && lhs.kind == rhs.kind
    }
}
