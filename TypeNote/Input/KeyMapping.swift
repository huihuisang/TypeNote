import Foundation

/// General MIDI instrument definitions with category grouping.
/// Covers all 128 standard GM programs across 16 categories.
struct KeyMapping {
    struct Instrument: Identifiable {
        let name: String
        let program: UInt8
        var id: UInt8 { program }
    }

    struct Category: Identifiable {
        let name: String
        let iconName: String
        let instruments: [Instrument]
        var id: String { name }
    }

    /// All 128 GM instruments organized by standard category
    static let categories: [Category] = [
        Category(name: "Piano", iconName: "pianokeys", instruments: [
            Instrument(name: "Acoustic Grand Piano",   program: 0),
            Instrument(name: "Bright Acoustic Piano",  program: 1),
            Instrument(name: "Electric Grand Piano",   program: 2),
            Instrument(name: "Honky-tonk Piano",       program: 3),
            Instrument(name: "Electric Piano 1",       program: 4),
            Instrument(name: "Electric Piano 2",       program: 5),
            Instrument(name: "Harpsichord",            program: 6),
            Instrument(name: "Clavinet",               program: 7),
        ]),
        Category(name: "Chromatic Perc.", iconName: "bell", instruments: [
            Instrument(name: "Celesta",        program: 8),
            Instrument(name: "Glockenspiel",   program: 9),
            Instrument(name: "Music Box",      program: 10),
            Instrument(name: "Vibraphone",     program: 11),
            Instrument(name: "Marimba",        program: 12),
            Instrument(name: "Xylophone",      program: 13),
            Instrument(name: "Tubular Bells",  program: 14),
            Instrument(name: "Dulcimer",       program: 15),
        ]),
        Category(name: "Organ", iconName: "music.quarternote.3", instruments: [
            Instrument(name: "Drawbar Organ",     program: 16),
            Instrument(name: "Percussive Organ",  program: 17),
            Instrument(name: "Rock Organ",        program: 18),
            Instrument(name: "Church Organ",      program: 19),
            Instrument(name: "Reed Organ",        program: 20),
            Instrument(name: "Accordion",         program: 21),
            Instrument(name: "Harmonica",         program: 22),
            Instrument(name: "Tango Accordion",   program: 23),
        ]),
        Category(name: "Guitar", iconName: "guitars", instruments: [
            Instrument(name: "Nylon Guitar",      program: 24),
            Instrument(name: "Steel Guitar",      program: 25),
            Instrument(name: "Jazz Guitar",       program: 26),
            Instrument(name: "Clean Guitar",      program: 27),
            Instrument(name: "Muted Guitar",      program: 28),
            Instrument(name: "Overdriven Guitar", program: 29),
            Instrument(name: "Distortion Guitar", program: 30),
            Instrument(name: "Guitar Harmonics",  program: 31),
        ]),
        Category(name: "Bass", iconName: "wave.3.right", instruments: [
            Instrument(name: "Acoustic Bass",          program: 32),
            Instrument(name: "Electric Bass (finger)", program: 33),
            Instrument(name: "Electric Bass (pick)",   program: 34),
            Instrument(name: "Fretless Bass",          program: 35),
            Instrument(name: "Slap Bass 1",            program: 36),
            Instrument(name: "Slap Bass 2",            program: 37),
            Instrument(name: "Synth Bass 1",           program: 38),
            Instrument(name: "Synth Bass 2",           program: 39),
        ]),
        Category(name: "Strings", iconName: "music.note", instruments: [
            Instrument(name: "Violin",            program: 40),
            Instrument(name: "Viola",             program: 41),
            Instrument(name: "Cello",             program: 42),
            Instrument(name: "Contrabass",        program: 43),
            Instrument(name: "Tremolo Strings",   program: 44),
            Instrument(name: "Pizzicato Strings", program: 45),
            Instrument(name: "Orchestral Harp",   program: 46),
            Instrument(name: "Timpani",           program: 47),
        ]),
        Category(name: "Ensemble", iconName: "person.3", instruments: [
            Instrument(name: "String Ensemble 1", program: 48),
            Instrument(name: "String Ensemble 2", program: 49),
            Instrument(name: "Synth Strings 1",   program: 50),
            Instrument(name: "Synth Strings 2",   program: 51),
            Instrument(name: "Choir Aahs",        program: 52),
            Instrument(name: "Voice Oohs",        program: 53),
            Instrument(name: "Synth Voice",       program: 54),
            Instrument(name: "Orchestra Hit",     program: 55),
        ]),
        Category(name: "Brass", iconName: "horn", instruments: [
            Instrument(name: "Trumpet",       program: 56),
            Instrument(name: "Trombone",      program: 57),
            Instrument(name: "Tuba",          program: 58),
            Instrument(name: "Muted Trumpet", program: 59),
            Instrument(name: "French Horn",   program: 60),
            Instrument(name: "Brass Section", program: 61),
            Instrument(name: "Synth Brass 1", program: 62),
            Instrument(name: "Synth Brass 2", program: 63),
        ]),
        Category(name: "Reed", iconName: "wind", instruments: [
            Instrument(name: "Soprano Sax",   program: 64),
            Instrument(name: "Alto Sax",      program: 65),
            Instrument(name: "Tenor Sax",     program: 66),
            Instrument(name: "Baritone Sax",  program: 67),
            Instrument(name: "Oboe",          program: 68),
            Instrument(name: "English Horn",  program: 69),
            Instrument(name: "Bassoon",       program: 70),
            Instrument(name: "Clarinet",      program: 71),
        ]),
        Category(name: "Pipe", iconName: "lines.measurement.horizontal", instruments: [
            Instrument(name: "Piccolo",       program: 72),
            Instrument(name: "Flute",         program: 73),
            Instrument(name: "Recorder",      program: 74),
            Instrument(name: "Pan Flute",     program: 75),
            Instrument(name: "Blown Bottle",  program: 76),
            Instrument(name: "Shakuhachi",    program: 77),
            Instrument(name: "Whistle",       program: 78),
            Instrument(name: "Ocarina",       program: 79),
        ]),
        Category(name: "Synth Lead", iconName: "waveform", instruments: [
            Instrument(name: "Lead: Square",     program: 80),
            Instrument(name: "Lead: Sawtooth",   program: 81),
            Instrument(name: "Lead: Calliope",   program: 82),
            Instrument(name: "Lead: Chiff",      program: 83),
            Instrument(name: "Lead: Charang",    program: 84),
            Instrument(name: "Lead: Voice",      program: 85),
            Instrument(name: "Lead: Fifths",     program: 86),
            Instrument(name: "Lead: Bass+Lead",  program: 87),
        ]),
        Category(name: "Synth Pad", iconName: "waveform.path", instruments: [
            Instrument(name: "Pad: New Age",   program: 88),
            Instrument(name: "Pad: Warm",      program: 89),
            Instrument(name: "Pad: Polysynth", program: 90),
            Instrument(name: "Pad: Choir",     program: 91),
            Instrument(name: "Pad: Bowed",     program: 92),
            Instrument(name: "Pad: Metallic",  program: 93),
            Instrument(name: "Pad: Halo",      program: 94),
            Instrument(name: "Pad: Sweep",     program: 95),
        ]),
        Category(name: "Synth FX", iconName: "sparkles", instruments: [
            Instrument(name: "FX: Rain",       program: 96),
            Instrument(name: "FX: Soundtrack", program: 97),
            Instrument(name: "FX: Crystal",    program: 98),
            Instrument(name: "FX: Atmosphere", program: 99),
            Instrument(name: "FX: Brightness", program: 100),
            Instrument(name: "FX: Goblins",    program: 101),
            Instrument(name: "FX: Echoes",     program: 102),
            Instrument(name: "FX: Sci-fi",     program: 103),
        ]),
        Category(name: "Ethnic", iconName: "globe", instruments: [
            Instrument(name: "Sitar",    program: 104),
            Instrument(name: "Banjo",    program: 105),
            Instrument(name: "Shamisen", program: 106),
            Instrument(name: "Koto",     program: 107),
            Instrument(name: "Kalimba",  program: 108),
            Instrument(name: "Bagpipe",  program: 109),
            Instrument(name: "Fiddle",   program: 110),
            Instrument(name: "Shanai",   program: 111),
        ]),
        Category(name: "Percussive", iconName: "metronome", instruments: [
            Instrument(name: "Tinkle Bell",    program: 112),
            Instrument(name: "Agogo",          program: 113),
            Instrument(name: "Steel Drums",    program: 114),
            Instrument(name: "Woodblock",      program: 115),
            Instrument(name: "Taiko Drum",     program: 116),
            Instrument(name: "Melodic Tom",    program: 117),
            Instrument(name: "Synth Drum",     program: 118),
            Instrument(name: "Reverse Cymbal", program: 119),
        ]),
        Category(name: "Sound Effects", iconName: "speaker.wave.2", instruments: [
            Instrument(name: "Guitar Fret Noise", program: 120),
            Instrument(name: "Breath Noise",      program: 121),
            Instrument(name: "Seashore",          program: 122),
            Instrument(name: "Bird Tweet",        program: 123),
            Instrument(name: "Telephone Ring",    program: 124),
            Instrument(name: "Helicopter",        program: 125),
            Instrument(name: "Applause",          program: 126),
            Instrument(name: "Gunshot",           program: 127),
        ]),
    ]

    /// Flat list of all instruments
    static let instruments: [(name: String, program: UInt8)] = {
        categories.flatMap { cat in
            cat.instruments.map { (name: $0.name, program: $0.program) }
        }
    }()

    /// Look up instrument name by program number
    static func instrumentName(for program: UInt8) -> String {
        instruments.first { $0.program == program }?.name ?? "Program \(program)"
    }

    /// Look up category name by program number
    static func categoryName(for program: UInt8) -> String {
        categories.first { cat in cat.instruments.contains { $0.program == program } }?.name ?? "Unknown"
    }

    /// Look up category icon by program number
    static func categoryIcon(for program: UInt8) -> String {
        categories.first { cat in cat.instruments.contains { $0.program == program } }?.iconName ?? "questionmark"
    }
}
