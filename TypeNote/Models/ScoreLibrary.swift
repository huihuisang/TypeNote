import SwiftUI
import Observation

/// Manages cached scores: persistence, import, and file copying.
@Observable @MainActor
final class ScoreLibrary {
    private(set) var items: [ScoreItem] = []

    private let fileManager = FileManager.default

    /// App Support directory for storing scores
    private var libraryURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("TypeNote", isDirectory: true)
    }

    /// Subdirectory for cached score files
    private var filesURL: URL {
        libraryURL.appendingPathComponent("ScoreFiles", isDirectory: true)
    }

    /// Index file storing all ScoreItem metadata
    private var indexURL: URL {
        libraryURL.appendingPathComponent("library.json")
    }

    private static let builtInSeededKey = "builtInScoresSeeded"
    /// Bump this version when built-in scores are added, updated, or removed.
    private static let builtInScoresVersion = 5

    /// Built-in scores removed in past versions — purged from library on migration.
    private static let removedBuiltInNames: Set<String> = [
        "Jingle Bells", "Moonlight Sonata", "Greensleeves", "Going Home", "Swan Lake Theme",
        "Somewhere Over the Rainbow", "Yesterday", "River Flows in You", "Interstellar Theme",
        "Yue Liang Dai Biao Wo De Xin", "Mo Li Hua", "Tong Nian", "Qian Qian Que Ge",
        "Qing Tian", "Qi Li Xiang", "Dao Xiang", "Ju Hua Tai", "Qing Hua Ci",
        "Ye Qu", "Gao Bai Qi Qiu", "Jian Dan Ai",
    ]

    init() {
        ensureDirectories()
        loadIndex()
        seedBuiltInScoresIfNeeded()
        migrateNewBuiltInScoresIfNeeded()
    }

    // MARK: - Public API

    /// Save a Jianpu score to the library.
    func saveJianpu(name: String, text: String, keyIndex: Int, bpm: Double) {
        if let idx = items.firstIndex(where: { $0.name == name && $0.type == .jianpu }) {
            items[idx].jianpuText = text
            items[idx].jianpuKeyIndex = keyIndex
            items[idx].bpm = bpm
        } else {
            var item = ScoreItem(name: name, type: .jianpu)
            item.jianpuText = text
            item.jianpuKeyIndex = keyIndex
            item.bpm = bpm
            items.insert(item, at: 0)
        }
        saveIndex()
    }

    /// Import a MusicXML or MIDI file: copy to cache and add to library.
    func importFile(url: URL, type: ScoreType, detectedBPM: Double? = nil) -> ScoreItem? {
        let name = url.deletingPathExtension().lastPathComponent

        // Copy file to cache directory with unique name
        let ext = url.pathExtension
        let cachedName = "\(UUID().uuidString).\(ext)"
        let destURL = filesURL.appendingPathComponent(cachedName)

        do {
            // Access security-scoped resource for sandboxed file access
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            try fileManager.copyItem(at: url, to: destURL)
        } catch {
            print("Failed to cache file: \(error)")
            return nil
        }

        var item = ScoreItem(name: name, type: type)
        item.cachedFileName = cachedName
        item.bpm = detectedBPM
        items.insert(item, at: 0)
        saveIndex()
        return item
    }

    /// Update an existing score item in the library.
    func update(_ item: ScoreItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx] = item
        saveIndex()
    }

    /// Get the cached file URL for a file-based score.
    func fileURL(for item: ScoreItem) -> URL? {
        guard let fileName = item.cachedFileName else { return nil }
        let url = filesURL.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    /// Reorder items by moving from source indices to destination.
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        saveIndex()
    }

    /// Remove a score from the library and delete its cached file.
    func remove(_ item: ScoreItem) {
        if let fileName = item.cachedFileName {
            let url = filesURL.appendingPathComponent(fileName)
            try? fileManager.removeItem(at: url)
        }
        items.removeAll { $0.id == item.id }
        saveIndex()
    }

    // MARK: - Built-in Scores

    /// Add built-in demo scores on first launch.
    private func seedBuiltInScoresIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.builtInSeededKey) else { return }

        for entry in BuiltInScores.all.reversed() {
            items.insert(makeItem(from: entry), at: 0)
        }

        saveIndex()
        UserDefaults.standard.set(true, forKey: Self.builtInSeededKey)
        UserDefaults.standard.set(Self.builtInScoresVersion, forKey: "builtInScoresVersion")
    }

    /// Migrate library to match the current built-in score list (add new, refresh existing, remove deleted).
    private func migrateNewBuiltInScoresIfNeeded() {
        let seededVersion = UserDefaults.standard.integer(forKey: "builtInScoresVersion")
        guard seededVersion < Self.builtInScoresVersion else { return }

        // Remove built-in scores that no longer exist (no cachedFileName = not an imported file)
        items.removeAll { Self.removedBuiltInNames.contains($0.name) && $0.cachedFileName == nil }

        let existingNames = Set(items.map { $0.name })
        for entry in BuiltInScores.all {
            if !existingNames.contains(entry.name) {
                // Add newly introduced built-in scores
                items.append(makeItem(from: entry))
            } else if let idx = items.firstIndex(where: { $0.name == entry.name && $0.type == .jianpu }) {
                // Refresh jianpu text and BPM for existing built-in scores
                items[idx].jianpuText = entry.text
                items[idx].bpm = entry.bpm
            }
        }

        saveIndex()
        UserDefaults.standard.set(Self.builtInScoresVersion, forKey: "builtInScoresVersion")
    }

    private func makeItem(from entry: BuiltInScores.Entry) -> ScoreItem {
        var item = ScoreItem(name: entry.name, type: .jianpu)
        item.jianpuText = entry.text
        item.jianpuKeyIndex = entry.keyIndex
        item.bpm = entry.bpm
        item.instrumentProgram = entry.instrumentProgram
        return item
    }

    // MARK: - Persistence

    private func ensureDirectories() {
        try? fileManager.createDirectory(at: filesURL, withIntermediateDirectories: true)
    }

    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([ScoreItem].self, from: data)
        else { return }
        items = decoded
    }

    private func saveIndex() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}
