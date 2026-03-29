import SwiftUI

/// Visual representation of the virtual piano keyboard.
struct KeyboardView: View {
    @Environment(AppState.self) private var appState

    // Layout constants
    private let whiteKeyWidth: CGFloat = 44
    private let whiteKeyHeight: CGFloat = 160
    private let blackKeyWidth: CGFloat = 28
    private let blackKeyHeight: CGFloat = 100

    // White keys and their keyboard shortcuts
    private let whiteKeys: [(char: String, note: String, midi: UInt8)] = [
        ("Z", "C3", 48), ("X", "D3", 50), ("C", "E3", 52), ("V", "F3", 53),
        ("B", "G3", 55), ("N", "A3", 57), ("M", "B3", 59),
        ("A", "C4", 60), ("S", "D4", 62), ("D", "E4", 64), ("F", "F4", 65),
        ("G", "G4", 67), ("H", "A4", 69), ("J", "B4", 71), ("K", "C5", 72),
        ("L", "D5", 74),
    ]

    // Black keys with their positions relative to white key indices
    private let blackKeys: [(char: String, note: String, midi: UInt8, afterWhiteIndex: Int)] = [
        ("2", "C#3", 49, 0), ("3", "D#3", 51, 1),
        ("5", "F#3", 54, 3), ("6", "G#3", 56, 4), ("7", "A#3", 58, 5),
        ("W", "C#4", 61, 7), ("E", "D#4", 63, 8),
        ("T", "F#4", 66, 10), ("Y", "G#4", 68, 11), ("U", "A#4", 70, 12),
    ]

    var body: some View {
        VStack(spacing: 8) {
            Text("Virtual Keyboard")
                .font(.headline)
                .foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                // White keys
                HStack(spacing: 2) {
                    ForEach(Array(whiteKeys.enumerated()), id: \.offset) { _, key in
                        WhiteKeyView(
                            label: key.char,
                            noteName: key.note,
                            isPressed: appState.activeKeys.contains(key.char.lowercased())
                        )
                        .frame(width: whiteKeyWidth, height: whiteKeyHeight)
                    }
                }

                // Black keys overlaid
                ForEach(Array(blackKeys.enumerated()), id: \.offset) { _, key in
                    BlackKeyView(
                        label: key.char,
                        isPressed: appState.activeKeys.contains(key.char.lowercased())
                    )
                    .frame(width: blackKeyWidth, height: blackKeyHeight)
                    .offset(
                        x: CGFloat(key.afterWhiteIndex) * (whiteKeyWidth + 2) + whiteKeyWidth - blackKeyWidth / 2 + 1,
                        y: 0
                    )
                }
            }

            Text("Press keys to play! White keys: home row & Z row. Black keys: number row & QWERTY row.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
    }
}

// MARK: - Key Views

struct WhiteKeyView: View {
    let label: String
    let noteName: String
    let isPressed: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(isPressed ? Color.blue.opacity(0.3) : Color.white)
                .shadow(color: .black.opacity(0.2), radius: 1, y: 1)

            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.gray.opacity(0.4), lineWidth: 1)

            VStack {
                Spacer()
                Text(noteName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(label)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(isPressed ? .blue : .primary)
                    .padding(.bottom, 8)
            }
        }
    }
}

struct BlackKeyView: View {
    let label: String
    let isPressed: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(isPressed ? Color.blue : Color.black)
                .shadow(color: .black.opacity(0.4), radius: 2, y: 2)

            VStack {
                Spacer()
                Text(label)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(isPressed ? .white : .gray)
                    .padding(.bottom, 6)
            }
        }
    }
}
