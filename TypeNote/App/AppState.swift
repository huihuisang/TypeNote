import Observation
import SwiftUI

/// Playback mode when a score finishes all notes.
enum PlayMode: String, CaseIterable, Codable {
    case singleRepeat
    case sequential
    case shuffle

    var label: LocalizedStringKey {
        switch self {
        case .singleRepeat: return "Single Repeat"
        case .sequential: return "Sequential"
        case .shuffle: return "Shuffle"
        }
    }

    var iconName: String {
        switch self {
        case .singleRepeat: return "repeat.1"
        case .sequential: return "arrow.right"
        case .shuffle: return "shuffle"
        }
    }
}

/// Central state: global keyboard listening → sequential note playback with auto-loop.
@Observable @MainActor
final class AppState {

    // MARK: - Audio

    let audioEngine = MultiSamplerPlayer()
    var audioReady = false
    var audioError: String?

    // MARK: - Score

    var score: [MusicNote] = []
    var currentNoteIndex = 0
    var scoreName = "Twinkle Twinkle"

    /// Increments each time a real note (not a rest) is played.
    var notePlayedCount = 0
    var activeScoreId: UUID? {
        didSet { saveActiveScoreId() }
    }

    // MARK: - Library

    let library = ScoreLibrary()
    let soundFontLibrary = SoundFontLibrary()

    // MARK: - Instrument

    var selectedInstrumentIndex = 0
    // Default instrument: Glockenspiel (GM program 9)
    var loadedPrograms: [UInt8] = [9]

    /// The currently active instrument — either a GM program or a custom SF2 preset.
    var activeInstrument: InstrumentRef = .gm(program: 9)

    /// GM program number of the active GM instrument (for backward-compat display).
    var activeProgram: UInt8 {
        if case .gm(let p) = activeInstrument { return p }
        return audioEngine.activeProgram
    }

    var selectedInstrumentName: String {
        switch activeInstrument {
        case .gm(let program):
            return KeyMapping.instruments.first { $0.program == program }?.name ?? "Piano"
        case .sf2(_, let preset):
            return preset.name
        }
    }

    // MARK: - Jianpu Input

    var jianpuText = "1 1 5 5 6 6 5 - 4 4 3 3 2 2 1 -"
    var jianpuKeyIndex = 0
    var jianpuTempo: Double = 120

    // MARK: - Playback

    var isEnabled = true
    /// Non-interrupt mode: ignore key events while a note (or rest) is still playing
    var nonInterruptMode = true

    var playMode: PlayMode = .singleRepeat {
        didSet { savePlayMode() }
    }

    /// Master instrument volume (0.0 = silent, 1.0 = full).
    var instrumentVolume: Float = 1.0 {
        didSet {
            audioEngine.setVolume(instrumentVolume)
            UserDefaults.standard.set(instrumentVolume, forKey: Self.instrumentVolumeKey)
        }
    }

    private var isNotePlaying = false
    private var lastPlayedNote: UInt8?
    private var noteStopTask: Task<Void, Never>?
    private var audioRecoveryTask: Task<Void, Never>?
    private var isRecoveringAudio = false
    // Tracks play count per note to avoid premature stop on rapid re-triggers
    private var notePlayCount: [UInt8: Int] = [:]

    // MARK: - Global Monitor

    private let globalMonitor = GlobalKeyboardMonitor()

    // MARK: - UserDefaults Keys

    private static let activeScoreIdKey = "activeScoreId"
    private static let playModeKey = "playMode"
    private static let instrumentVolumeKey = "instrumentVolume"

    // MARK: - Initialization

    init() {
        // Restore volume before audio setup so the engine starts at the saved level
        let savedVolume = UserDefaults.standard.float(forKey: Self.instrumentVolumeKey)
        instrumentVolume = savedVolume > 0 ? savedVolume : 0.3
        bindAudioEngineCallbacks()
        setupAudio()
        restorePlayMode()
        restoreLastScore()
        setupGlobalMonitor()
    }

    deinit {
        MainActor.assumeIsolated {
            audioRecoveryTask?.cancel()
            noteStopTask?.cancel()
            previewTask?.cancel()
            scorePreviewTask?.cancel()
            globalMonitor.stop()
        }
    }

    // MARK: - Audio

    private func setupAudio() {
        do {
            try audioEngine.setup(programs: loadedPrograms)
            audioReady = true
            audioError = nil
            loadedProgramSet = Set(loadedPrograms)
            audioEngine.setVolume(instrumentVolume)
        } catch {
            audioError = error.localizedDescription
            audioReady = false
        }
    }

    private func bindAudioEngineCallbacks() {
        audioEngine.onConfigurationChange = { [weak self] in
            Task { @MainActor [weak self] in
                self?.scheduleAudioRecovery()
            }
        }
    }

    private func scheduleAudioRecovery() {
        audioRecoveryTask?.cancel()
        audioRecoveryTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled, let self else { return }
            self.recoverAudioAfterDeviceChange()
        }
    }

    private func recoverAudioAfterDeviceChange() {
        guard audioReady, !isRecoveringAudio else { return }

        isRecoveringAudio = true
        cancelPlaybackTasksForAudioRecovery()

        do {
            try audioEngine.rebuildAfterOutputDeviceChange()
            audioEngine.setVolume(instrumentVolume)
            audioReady = true
            audioError = nil
        } catch {
            audioReady = false
            audioError = "Audio output changed and the audio engine could not recover: \(error.localizedDescription)"
        }

        isRecoveringAudio = false
    }

    private func cancelPlaybackTasksForAudioRecovery() {
        noteStopTask?.cancel()
        noteStopTask = nil

        previewTask?.cancel()
        previewTask = nil

        scorePreviewTask?.cancel()
        scorePreviewTask = nil

        isNotePlaying = false
        lastPlayedNote = nil
        notePlayCount.removeAll()
    }

    // MARK: - Persistence

    private func saveActiveScoreId() {
        if let id = activeScoreId {
            UserDefaults.standard.set(id.uuidString, forKey: Self.activeScoreIdKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.activeScoreIdKey)
        }
    }

    private func savePlayMode() {
        UserDefaults.standard.set(playMode.rawValue, forKey: Self.playModeKey)
    }

    private func restorePlayMode() {
        if let raw = UserDefaults.standard.string(forKey: Self.playModeKey),
           let mode = PlayMode(rawValue: raw)
        {
            playMode = mode
        }
    }

    /// Restore the last active score from library on launch.
    private func restoreLastScore() {
        if let idString = UserDefaults.standard.string(forKey: Self.activeScoreIdKey),
           let id = UUID(uuidString: idString),
           let item = library.items.first(where: { $0.id == id })
        {
            loadFromLibrary(item)
        } else if let first = library.items.first {
            loadFromLibrary(first)
        } else {
            loadJianpu()
        }
    }

    // MARK: - Global Keyboard Monitor (any key → next note)

    private func setupGlobalMonitor() {
        globalMonitor.onKeyDown = { [weak self] keyCode in
            guard let self else { return }
            Task { @MainActor in
                self.playNextNote(keyCode: keyCode)
            }
        }
        globalMonitor.start()
    }

    /// Restart the keyboard monitor after permission is granted.
    func restartMonitorIfNeeded() {
        guard PermissionManager.hasInputMonitoring else { return }
        globalMonitor.stop()
        globalMonitor.start()
    }

    // MARK: - Playback

    private func playNextNote(keyCode: Int64) {
        guard isEnabled, audioReady, !isRecoveringAudio, !score.isEmpty else { return }

        if nonInterruptMode, isNotePlaying { return }

        if currentNoteIndex >= score.count {
            switch playMode {
            case .singleRepeat:
                currentNoteIndex = 0
            case .sequential:
                advanceToNextScore()
                return
            case .shuffle:
                advanceToRandomScore()
                return
            }
        }

        let note = score[currentNoteIndex]
        currentNoteIndex += 1

        if let prev = lastPlayedNote {
            audioEngine.stopNote(prev)
        }

        isNotePlaying = true
        noteStopTask?.cancel()

        guard !note.isRest else {
            lastPlayedNote = nil
            noteStopTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(note.duration))
                guard !Task.isCancelled, let self else { return }
                self.isNotePlaying = false
            }
            return
        }

        audioEngine.playNote(note.midiNote, velocity: note.velocity)
        notePlayedCount += 1
        lastPlayedNote = note.midiNote

        let midiNote = note.midiNote
        let count = (notePlayCount[midiNote] ?? 0) + 1
        notePlayCount[midiNote] = count

        noteStopTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(note.duration))
            guard !Task.isCancelled, let self else { return }
            self.isNotePlaying = false
            if self.notePlayCount[midiNote] == count {
                self.audioEngine.stopNote(midiNote)
                if self.lastPlayedNote == midiNote {
                    self.lastPlayedNote = nil
                }
            }
        }
    }

    // MARK: - Play Mode Navigation

    private func advanceToNextScore() {
        guard let currentId = activeScoreId,
              let currentIndex = library.items.firstIndex(where: { $0.id == currentId })
        else {
            currentNoteIndex = 0
            return
        }
        let nextIndex = (currentIndex + 1) % library.items.count
        loadFromLibrary(library.items[nextIndex])
    }

    private func advanceToRandomScore() {
        guard library.items.count > 1,
              let currentId = activeScoreId
        else {
            currentNoteIndex = 0
            return
        }
        let candidates = library.items.filter { $0.id != currentId }
        if let random = candidates.randomElement() {
            loadFromLibrary(random)
        } else {
            currentNoteIndex = 0
        }
    }

    // MARK: - Instrument

    /// Set of loaded GM program numbers (for LOADED badge in the UI).
    private(set) var loadedProgramSet: Set<UInt8> = [9]

    /// Check if a GM program is already loaded in memory.
    func isInstrumentLoaded(_ program: UInt8) -> Bool {
        loadedProgramSet.contains(program)
    }

    /// Task handle for the instrument preview melody, cancelled on each new selection.
    private var previewTask: Task<Void, Never>?

    /// Task handle for score card hover-preview playback.
    private var scorePreviewTask: Task<Void, Never>?

    /// Select a GM instrument by program number.
    func selectInstrument(program: UInt8, preview: Bool = true) {
        selectInstrument(.gm(program: program), preview: preview)
    }

    /// Select any instrument via `InstrumentRef` (GM or custom SF2 preset).
    func selectInstrument(_ ref: InstrumentRef, preview: Bool = true) {
        guard !isRecoveringAudio else { return }
        switch ref {
        case .gm(let program):
            do {
                try audioEngine.loadInstrumentIfNeeded(program: program)
                audioEngine.switchInstrument(to: program)
                activeInstrument = .gm(program: program)
                loadedProgramSet.insert(program)
                if let idx = loadedPrograms.firstIndex(of: program) {
                    selectedInstrumentIndex = idx
                }
                if preview { previewCurrentInstrument() }
            } catch {
                audioError = String(format: String(localized: "Failed to load instrument: %@"),
                                   error.localizedDescription)
            }

        case .sf2(let sf2ID, let preset):
            guard let font = soundFontLibrary.soundFonts.first(where: { $0.id == sf2ID }),
                  let fileURL = soundFontLibrary.fileURL(for: font)
            else { return }
            do {
                try audioEngine.loadCustomPreset(sf2URL: fileURL, preset: preset)
                activeInstrument = .sf2(sf2ID: sf2ID, preset: preset)
                if preview { previewCurrentInstrument() }
            } catch {
                audioError = String(format: String(localized: "Failed to load instrument: %@"),
                                   error.localizedDescription)
            }
        }
    }

    /// Play a short C major arpeggio so the user can audition the selected instrument.
    private func previewCurrentInstrument() {
        previewTask?.cancel()
        let notes: [(note: UInt8, hold: TimeInterval, gap: TimeInterval)] = [
            (60, 0.30, 0.05),
            (64, 0.30, 0.05),
            (67, 0.30, 0.05),
            (72, 0.50, 0.00),
        ]
        let ref = activeInstrument
        previewTask = Task {
            for step in notes {
                guard !Task.isCancelled, activeInstrument == ref else { break }
                audioEngine.playNote(step.note, velocity: 75)
                try? await Task.sleep(for: .seconds(step.hold))
                audioEngine.stopNote(step.note)
                if step.gap > 0 {
                    try? await Task.sleep(for: .seconds(step.gap))
                }
            }
        }
    }

    /// Play through all notes of a score item as a hover preview (independent of main playback).
    func previewScore(_ item: ScoreItem) {
        guard !isRecoveringAudio else { return }
        stopScorePreview()

        let bpm = item.bpm ?? 120
        var notes: [MusicNote] = []

        switch item.type {
        case .jianpu:
            let keyMidi = JianpuParser.keys[item.jianpuKeyIndex ?? 0].midi
            notes = JianpuParser(key: keyMidi, tempo: bpm).parse(item.jianpuText ?? "")
        case .musicXML:
            guard let url = library.fileURL(for: item) else { return }
            notes = MusicXMLParser().parse(url: url)
        case .midi:
            guard let url = library.fileURL(for: item) else { return }
            notes = MIDIFileParser(tempo: bpm, override: item.bpm != nil).parse(url: url)
        }

        guard !notes.isEmpty else { return }

        scorePreviewTask = Task {
            for note in notes {
                guard !Task.isCancelled else { break }
                if !note.isRest {
                    audioEngine.playNote(note.midiNote, velocity: note.velocity)
                }
                try? await Task.sleep(for: .seconds(note.duration))
                if !note.isRest {
                    audioEngine.stopNote(note.midiNote)
                }
            }
        }
    }

    func stopScorePreview() {
        scorePreviewTask?.cancel()
        scorePreviewTask = nil
        audioEngine.stopAllNotes()
    }

    func switchInstrument(to index: Int) {
        guard index < loadedPrograms.count else { return }
        selectedInstrumentIndex = index
        let program = loadedPrograms[index]
        audioEngine.switchInstrument(to: program)
        activeInstrument = .gm(program: program)
    }

    // MARK: - Score Loading

    func loadJianpu() {
        let keyMidi = JianpuParser.keys[jianpuKeyIndex].midi
        let parser = JianpuParser(key: keyMidi, tempo: jianpuTempo)
        score = parser.parse(jianpuText)
        currentNoteIndex = 0
        scoreName = String(localized: "Custom Score")
    }

    func loadMusicXML(url: URL) {
        scoreName = url.deletingPathExtension().lastPathComponent
        let parser = MusicXMLParser()
        score = parser.parse(url: url)
        currentNoteIndex = 0
    }

    func loadMIDIFile(url: URL) {
        scoreName = url.deletingPathExtension().lastPathComponent
        let parser = MIDIFileParser(tempo: jianpuTempo)
        score = parser.parse(url: url)
        currentNoteIndex = 0
    }

    func resetPlayback() {
        currentNoteIndex = 0
        noteStopTask?.cancel()
        noteStopTask = nil
        isNotePlaying = false
        lastPlayedNote = nil
        notePlayCount.removeAll()
        audioEngine.stopAllNotes()
    }

    // MARK: - Library Integration

    func loadFromLibrary(_ item: ScoreItem) {
        activeScoreId = item.id
        scoreName = item.name
        let bpm = item.bpm ?? 120

        switch item.type {
        case .jianpu:
            let keyMidi = JianpuParser.keys[item.jianpuKeyIndex ?? 0].midi
            score = JianpuParser(key: keyMidi, tempo: bpm).parse(item.jianpuText ?? "")
        case .musicXML:
            guard let url = library.fileURL(for: item) else { return }
            let parser = MusicXMLParser()
            if item.bpm != nil {
                let result = parser.parseWithBPM(url: url)
                let ratio = result.bpm / bpm
                score = result.notes.map { $0.scaled(durationBy: ratio) }
            } else {
                score = parser.parse(url: url)
            }
        case .midi:
            guard let url = library.fileURL(for: item) else { return }
            score = MIDIFileParser(tempo: bpm, override: item.bpm != nil).parse(url: url)
        }

        currentNoteIndex = 0
    }

    func importFileWithBPM(url: URL, type: ScoreType) {
        var detectedBPM: Double?

        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        switch type {
        case .musicXML:
            let result = MusicXMLParser().parseWithBPM(url: url)
            detectedBPM = result.bpm
        case .midi:
            let result = MIDIFileParser().parseWithBPM(url: url)
            detectedBPM = result.bpm
        case .jianpu:
            break
        }

        if let item = library.importFile(url: url, type: type, detectedBPM: detectedBPM) {
            loadFromLibrary(item)
        }
    }
}
