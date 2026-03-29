import Foundation

/// Unified note representation used across all parsers (Jianpu, MusicXML, MIDI).
struct MusicNote: Codable, Equatable, Identifiable {
    let id: UUID
    let midiNote: UInt8        // MIDI note number, middle C = 60
    let duration: TimeInterval // Duration in seconds
    let velocity: UInt8        // Velocity 0–127
    let isRest: Bool           // Whether this is a rest

    init(midiNote: UInt8, duration: TimeInterval, velocity: UInt8, isRest: Bool) {
        self.id = UUID()
        self.midiNote = midiNote
        self.duration = duration
        self.velocity = velocity
        self.isRest = isRest
    }

    static func note(_ midi: UInt8, duration: TimeInterval, velocity: UInt8 = 80) -> MusicNote {
        MusicNote(midiNote: midi, duration: duration, velocity: velocity, isRest: false)
    }

    static func rest(duration: TimeInterval) -> MusicNote {
        MusicNote(midiNote: 0, duration: duration, velocity: 0, isRest: true)
    }

    /// Human-readable note name (e.g. "C4", "F#5")
    var noteName: String {
        guard !isRest else { return "Rest" }
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(midiNote) / 12 - 1
        let name = names[Int(midiNote) % 12]
        return "\(name)\(octave)"
    }
}
