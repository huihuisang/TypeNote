import Foundation

/// Defines the keyboard-to-MIDI-note mapping modes and default layouts.
enum KeyMappingMode: String, CaseIterable, Codable {
    case sequential  // Each key press plays the next note in the score
    case mapped      // Keys are mapped to specific MIDI notes
}

/// Standard DAW piano keyboard layout.
/// Home row = white keys, upper row = black keys.
struct KeyMapping {
    /// Default piano layout: ASDFGHJK = white keys, WETYU = black keys
    /// Maps from C4 (MIDI 60) upward
    static let defaultPianoLayout: [String: UInt8] = [
        // White keys (home row) - C4 to C5
        "a": 60,  // C4
        "s": 62,  // D4
        "d": 64,  // E4
        "f": 65,  // F4
        "g": 67,  // G4
        "h": 69,  // A4
        "j": 71,  // B4
        "k": 72,  // C5
        "l": 74,  // D5

        // Black keys (upper row)
        "w": 61,  // C#4
        "e": 63,  // D#4
        "t": 66,  // F#4
        "y": 68,  // G#4
        "u": 70,  // A#4

        // Lower octave (Z row) - C3 to B3
        "z": 48,  // C3
        "x": 50,  // D3
        "c": 52,  // E3
        "v": 53,  // F3
        "b": 55,  // G3
        "n": 57,  // A3
        "m": 59,  // B3

        // Lower octave black keys (number row)
        "2": 49,  // C#3
        "3": 51,  // D#3
        "5": 54,  // F#3
        "6": 56,  // G#3
        "7": 58,  // A#3
    ]

    /// Common General MIDI instrument programs
    static let instruments: [(name: String, program: UInt8)] = [
        ("Acoustic Grand Piano", 0),
        ("Bright Acoustic Piano", 1),
        ("Electric Grand Piano", 2),
        ("Honky-tonk Piano", 3),
        ("Electric Piano 1", 4),
        ("Electric Piano 2", 5),
        ("Harpsichord", 6),
        ("Clavinet", 7),
        ("Celesta", 8),
        ("Glockenspiel", 9),
        ("Music Box", 10),
        ("Vibraphone", 11),
        ("Marimba", 12),
        ("Xylophone", 13),
        ("Nylon Guitar", 24),
        ("Steel Guitar", 25),
        ("Jazz Guitar", 26),
        ("Clean Guitar", 27),
        ("Acoustic Bass", 32),
        ("Electric Bass (finger)", 33),
        ("Violin", 40),
        ("Viola", 41),
        ("Cello", 42),
        ("Contrabass", 43),
        ("Trumpet", 56),
        ("Trombone", 57),
        ("Tuba", 58),
        ("French Horn", 60),
        ("Soprano Sax", 64),
        ("Alto Sax", 65),
        ("Tenor Sax", 66),
        ("Flute", 73),
        ("Recorder", 74),
        ("Pan Flute", 75),
        ("Synth Lead 1 (square)", 80),
        ("Synth Lead 2 (sawtooth)", 81),
        ("Synth Pad 1 (new age)", 88),
        ("Synth Pad 2 (warm)", 89),
    ]
}
