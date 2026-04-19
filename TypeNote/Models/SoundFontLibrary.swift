import Foundation
import Observation

/// Manages imported SF2 SoundFont files: storage, parsing, and persistence.
///
/// Files are copied to `Application Support/TypeNote/SoundFonts/`.
/// Metadata (display name + preset list) is serialised to `soundfonts.json`.
@Observable @MainActor
final class SoundFontLibrary {

    private(set) var soundFonts: [SoundFont] = []

    private let fileManager = FileManager.default

    // MARK: - Directories

    private var soundFontsDir: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("TypeNote", isDirectory: true)
            .appendingPathComponent("SoundFonts", isDirectory: true)
    }

    private var indexURL: URL {
        soundFontsDir
            .deletingLastPathComponent()  // TypeNote/
            .appendingPathComponent("soundfonts.json")
    }

    // MARK: - Init

    init() {
        try? fileManager.createDirectory(at: soundFontsDir, withIntermediateDirectories: true)
        loadIndex()
    }

    // MARK: - Public API

    /// Import an SF2 file: copy it to the cache directory, parse its presets, and persist.
    /// Returns the created `SoundFont` on success, `nil` if the file is unreadable or has no presets.
    @discardableResult
    func `import`(url: URL) -> SoundFont? {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        // Parse presets before copying so we bail early on invalid files
        let presets = SF2Parser.parsePresets(from: url)
        guard !presets.isEmpty else { return nil }

        let destFileName = UUID().uuidString + ".sf2"
        let destURL = soundFontsDir.appendingPathComponent(destFileName)

        do {
            try fileManager.copyItem(at: url, to: destURL)
        } catch {
            print("SoundFontLibrary: copy failed — \(error)")
            return nil
        }

        let displayName = url.deletingPathExtension().lastPathComponent
        let font = SoundFont(displayName: displayName, fileName: destFileName, presets: presets)
        soundFonts.insert(font, at: 0)
        saveIndex()
        return font
    }

    /// Remove an imported SF2 file from disk and the index.
    func remove(_ font: SoundFont) {
        let fileURL = soundFontsDir.appendingPathComponent(font.fileName)
        try? fileManager.removeItem(at: fileURL)
        soundFonts.removeAll { $0.id == font.id }
        saveIndex()
    }

    /// Resolve the on-disk URL for a stored SoundFont.
    func fileURL(for font: SoundFont) -> URL? {
        let url = soundFontsDir.appendingPathComponent(font.fileName)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Persistence

    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([SoundFont].self, from: data)
        else { return }
        soundFonts = decoded
    }

    private func saveIndex() {
        guard let data = try? JSONEncoder().encode(soundFonts) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}
