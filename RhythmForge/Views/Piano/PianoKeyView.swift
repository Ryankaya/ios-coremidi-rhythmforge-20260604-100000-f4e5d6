import SwiftUI

struct PianoKeyView: View {
    let pitch:      UInt8
    let isBlack:    Bool
    let isPressed:  Bool
    let isExternal: Bool   // lit by incoming MIDI (from external device)

    var onDown: () -> Void
    var onUp:   () -> Void

    var body: some View {
        if isBlack {
            blackKey
        } else {
            whiteKey
        }
    }

    // MARK: - White key

    private var whiteKey: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(whiteKeyFill)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
            .overlay(
                Text(MIDIConstants.noteName(for: pitch))
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(isPressed ? .white : .gray.opacity(0.6))
                    .padding(.bottom, 4),
                alignment: .bottom
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onDown() }
                    .onEnded   { _ in onUp() }
            )
    }

    private var whiteKeyFill: some ShapeStyle {
        if isPressed {
            return AnyShapeStyle(
                LinearGradient(colors: [.cyan, .blue.opacity(0.8)], startPoint: .top, endPoint: .bottom)
            )
        } else if isExternal {
            return AnyShapeStyle(
                LinearGradient(colors: [.green.opacity(0.7), .teal.opacity(0.5)], startPoint: .top, endPoint: .bottom)
            )
        } else {
            return AnyShapeStyle(Color.white)
        }
    }

    // MARK: - Black key

    private var blackKey: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(blackKeyFill)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.black.opacity(0.6), lineWidth: 1)
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onDown() }
                    .onEnded   { _ in onUp() }
            )
    }

    private var blackKeyFill: some ShapeStyle {
        if isPressed {
            return AnyShapeStyle(
                LinearGradient(colors: [.cyan.opacity(0.9), .indigo], startPoint: .top, endPoint: .bottom)
            )
        } else if isExternal {
            return AnyShapeStyle(Color.green.opacity(0.7))
        } else {
            return AnyShapeStyle(
                LinearGradient(colors: [Color(white: 0.15), Color(white: 0.05)], startPoint: .top, endPoint: .bottom)
            )
        }
    }
}
