import Foundation

/// Parses Jianpu (numbered musical notation) into MusicNote arrays.
///
/// Jianpu rules:
/// - 1-7: do re mi fa sol la ti
/// - 0: rest
/// - `'`: raise one octave
/// - `,`: lower one octave
/// - `_`: halve the duration (each underscore halves it again)
/// - `-`: extend previous note by one beat
/// - `#`: sharp (before the digit)
/// - `b`: flat (before the digit, followed by a number)
///
/// Example: "1 1 5 5 6 6 5 - 4 4 3 3 2 2 1 -" = Twinkle Twinkle Little Star
struct JianpuParser {
    /// Scale degree to semitone intervals (C major: 1=0, 2=2, 3=4, 4=5, 5=7, 6=9, 7=11)
    private static let scaleIntervals: [Int: Int] = [
        1: 0, 2: 2, 3: 4, 4: 5, 5: 7, 6: 9, 7: 11
    ]

    /// Root MIDI note of the key. C4 = 60, D4 = 62, G4 = 67, etc.
    let key: UInt8

    /// Tempo in beats per minute. Must be positive.
    let tempo: Double

    init(key: UInt8, tempo: Double) {
        precondition(tempo > 0, "Tempo must be positive")
        self.key = key
        self.tempo = tempo
    }

    /// Duration of one quarter note in seconds.
    private var quarterDuration: TimeInterval { 60.0 / tempo }

    /// Available key signatures with their root MIDI notes.
    static let keys: [(name: String, midi: UInt8)] = [
        ("C", 60), ("C#/Db", 61), ("D", 62), ("D#/Eb", 63),
        ("E", 64), ("F", 65), ("F#/Gb", 66), ("G", 67),
        ("G#/Ab", 68), ("A", 69), ("A#/Bb", 70), ("B", 71)
    ]

    func parse(_ input: String) -> [MusicNote] {
        let tokens = input.split(separator: " ").map(String.init)
        var notes: [MusicNote] = []

        for token in tokens {
            // Tie "-": extend the previous note by one beat
            if token == "-", let last = notes.last {
                notes.removeLast()
                notes.append(MusicNote(
                    midiNote: last.midiNote,
                    duration: last.duration + quarterDuration,
                    velocity: last.velocity,
                    isRest: last.isRest
                ))
                continue
            }

            let chars = Array(token)
            var idx = 0
            var accidental = 0

            // Check for sharp/flat prefix: #1 or b1
            if idx < chars.count && chars[idx] == "#" {
                accidental = 1
                idx += 1
            } else if idx < chars.count && chars[idx] == "b"
                        && idx + 1 < chars.count && chars[idx + 1].isNumber {
                accidental = -1
                idx += 1
            }

            // Parse the scale degree (0-7)
            guard idx < chars.count,
                  let degree = chars[idx].wholeNumberValue,
                  (0...7).contains(degree)
            else { continue }
            idx += 1

            // Rest
            if degree == 0 {
                notes.append(.rest(duration: quarterDuration))
                continue
            }

            // Parse octave markers: ' up, , down
            var octaveShift = 0
            while idx < chars.count {
                // Accept both ASCII and smart quotes for octave markers
                if chars[idx] == "'" || chars[idx] == "\u{2019}" || chars[idx] == "\u{2018}" {
                    octaveShift += 1; idx += 1
                } else if chars[idx] == "," || chars[idx] == "\u{FF0C}" {
                    octaveShift -= 1; idx += 1
                } else { break }
            }

            // Parse duration underscores: each _ halves the duration
            var underscores = 0
            while idx < chars.count && chars[idx] == "_" {
                underscores += 1
                idx += 1
            }
            let beats = underscores > 0 ? 1.0 / pow(2.0, Double(underscores)) : 1.0

            // Calculate MIDI note
            let interval = Self.scaleIntervals[degree]!
            let midi = Int(key) + interval + (octaveShift * 12) + accidental
            guard (0...127).contains(midi) else { continue }

            notes.append(.note(UInt8(midi), duration: beats * quarterDuration))
        }

        return notes
    }
}
