import Foundation

/// Built-in demo scores bundled with the app.
/// Each entry defines a name, key index (into JianpuParser.keys), BPM, jianpu text, and category.
enum BuiltInScores {
    struct Entry {
        let name: String
        let keyIndex: Int  // 0=C, 1=C#, 2=D, ... 11=B
        let bpm: Double
        /// Category id — matches a ScoreCategory.id
        let category: String
        let text: String
        /// Optional GM program to auto-select when loaded (nil = keep current instrument)
        let instrumentProgram: UInt8? = nil
    }

    // MARK: - Score Categories

    struct ScoreCategory: Identifiable {
        let id: String
        let name: String       // localization key
        let iconName: String
    }

    static let scoreCategories: [ScoreCategory] = [
        ScoreCategory(id: "children",  name: "Children",   iconName: "face.smiling"),
        ScoreCategory(id: "classical", name: "Classical",  iconName: "music.quarternote.3"),
        ScoreCategory(id: "pop",       name: "Pop & Film", iconName: "film"),
        ScoreCategory(id: "ambient",   name: "Ambient",    iconName: "waveform"),
    ]

    /// Returns the category id for a built-in score by name (nil if user-added).
    static func categoryId(for name: String) -> String? { categoryMap[name] }

    private static let categoryMap: [String: String] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.name, $0.category) }
    )

    // MARK: - All Built-in Scores

    static let all: [Entry] = [

        // ── Children ─────────────────────────────────────────────────────────

        // 1. Twinkle Twinkle Little Star — C major, simple quarter notes
        Entry(
            name: "Twinkle Twinkle Little Star",
            keyIndex: 0, bpm: 120, category: "children",
            text: """
            1 1 5 5 6 6 5 - 4 4 3 3 2 2 1 - \
            5 5 4 4 3 3 2 - 5 5 4 4 3 3 2 - \
            1 1 5 5 6 6 5 - 4 4 3 3 2 2 1 -
            """
        ),

        // 2. Happy Birthday — C major, 3/4 feel
        Entry(
            name: "Happy Birthday",
            keyIndex: 0, bpm: 100, category: "children",
            text: """
            5_ 5_ 6 5 1' 7 - \
            5_ 5_ 6 5 2' 1' - \
            5_ 5_ 5' 3' 1' 7 6 \
            4'_ 4'_ 3' 1' 2' 1' -
            """
        ),

        // ── Classical ─────────────────────────────────────────────────────────

        // 3. Canon in D — D major, main melody
        Entry(
            name: "Canon in D",
            keyIndex: 2, bpm: 72, category: "classical",
            text: """
            5 - 3 - 4 - 5 - 6 - 3 - 4 - 5 - \
            1 - 6, - 7, - 1 - 2 - 7, - 1 - 2 - \
            3 - 1 - 2 - 3 - 4 - 2 - 3 - 4 - \
            5 - 3 - 4 - 2 - 3 - 1 - 2 - 7, -
            """
        ),

        // 4. Ode to Joy (Beethoven) — C major
        Entry(
            name: "Ode to Joy",
            keyIndex: 0, bpm: 120, category: "classical",
            text: """
            3 3 4 5 5 4 3 2 1 1 2 3 3 - 2 2 - \
            3 3 4 5 5 4 3 2 1 1 2 3 2 - 1 1 - \
            2 2 3 1 2 3_ 4_ 3 1 2 3_ 4_ 3 2 1 2 5, - \
            3 3 4 5 5 4 3 2 1 1 2 3 2 - 1 1 -
            """
        ),

        // 5. Amazing Grace — C major, 3/4 feel
        Entry(
            name: "Amazing Grace",
            keyIndex: 0, bpm: 80, category: "classical",
            text: """
            5, - 1 - 3_ 1_ 3 - 2 - 1 - 6, - \
            5, - 1 - 3_ 1_ 3 - 2 - 3 - 5 - \
            3 - 5_ 3_ 5 - 3 - 1 - 3_ 2_ 1 - 6, - \
            5, - 1 - 3_ 1_ 3 - 2 - 1 - 1 -
            """
        ),

        // 6. Für Elise (main theme simplified) — A minor
        Entry(
            name: "Fur Elise",
            keyIndex: 0, bpm: 110, category: "classical",
            text: """
            3'_ 2'#_ 3'_ 2'#_ 3'_ 7_ 2'_ 1'_ 6 - \
            1_ 3_ 6_ 7 - 3_ #5_ 7_ 1' - \
            3_ 3'_ 2'#_ 3'_ 2'#_ 3'_ 7_ 2'_ 1'_ 6 - \
            1_ 3_ 6_ 7 - 3_ 1'_ 7_ 6 -
            """
        ),

        // ── Pop & Film ────────────────────────────────────────────────────────

        // 7. My Heart Will Go On — C major
        Entry(
            name: "My Heart Will Go On",
            keyIndex: 0, bpm: 100, category: "pop",
            text: """
            1 2 3 3 - 3 2 3 5 - 5 3 2 1 - \
            1 2 3 3 - 3 2 3 2 - 1 1 - - \
            1 2 3 3 - 3 2 3 5 - 5 3 2 1 - \
            1 2 3 3 - 3 5 6 5 - 3 3 - -
            """
        ),

        // 8. Castle in the Sky (天空之城) — C major
        Entry(
            name: "Castle in the Sky",
            keyIndex: 0, bpm: 86, category: "pop",
            text: """
            6_ 7_ 1' - 7_ 1'_ 3' - 7 - - \
            3_ 6_ 5 - 3_ 5_ 6 - - - \
            3_ 3_ 4'_ 3'_ 2'_ 1'_ 3' - 7 - - \
            3_ 3_ 4'_ 3'_ 2'_ 1'_ 2' - 5 - - \
            6_ 7_ 1' - 7_ 1'_ 3' - 3 - - \
            6_ 7_ 1' - 7_ 3'_ 2' - - 1' -
            """
        ),

        // ── Ambient ───────────────────────────────────────────────────────────

        // 9. Ocean Waves — C pentatonic, Seashore (GM 122), ~3.2 min loop
        // A (bars 1-8) distant swell · B (9-16) rising surge · C (17-24) crest · D (25-32) retreating tide
        Entry(
            name: "Ocean Waves",
            keyIndex: 0, bpm: 40, category: "ambient",
            text: """
            1 - - - 2 - - - 3 - - - 2 - - - 1 - - - 6, - - - 5, - - - 1 - - - \
            2 - - - 3 - - - 5 - - - 6 - - - 5 - - - 3 - - - 2 - - - 3 - - - \
            5 - - - 6 - - - 5 - - - 3 - - - 6 - - - 5 - - - 3 - - - 2 - - - \
            1 - - - 6, - - - 1 - - - 2 - - - 3 - - - 2 - - - 1 - - - 1 - - -
            """,
        ),
    ]
}
