import SwiftUI
import Observation

/// Central state manager coordinating keyboard input, audio engine, score data, and key mappings.
@Observable @MainActor
final class AppState {
    // MARK: - Audio
    let audioEngine = MultiSamplerPlayer()
    var audioReady = false
    var audioError: String?

    // MARK: - Score
    var score: [MusicNote] = []
    var currentNoteIndex = 0

    // MARK: - Mode & Mapping
    var keyMappingMode: KeyMappingMode = .mapped
    var keyMappings: [String: UInt8] = KeyMapping.defaultPianoLayout

    // MARK: - Instrument
    var selectedInstrumentIndex = 0
    var loadedPrograms: [UInt8] = [0, 24, 25, 40, 56, 73, 80] // Piano, guitars, violin, trumpet, flute, synth

    // MARK: - Input
    var useGlobalMonitor = false
    var activeKeys: Set<String> = []

    // MARK: - Jianpu Input
    var jianpuText = "1 1 5 5 6 6 5 - 4 4 3 3 2 2 1 -"
    var jianpuKeyIndex = 0  // Index into JianpuParser.keys
    var jianpuTempo: Double = 120

    // MARK: - Local Monitor
    private var localKeyDownMonitor: Any?
    private var localKeyUpMonitor: Any?

    // MARK: - Global Monitor
    private let globalMonitor = GlobalKeyboardMonitor()

    // MARK: - Key code to character mapping (macOS virtual key codes)
    private static let keyCodeToChar: [UInt16: String] = [
        0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x",
        8: "c", 9: "v", 11: "b", 12: "q", 13: "w", 14: "e", 15: "r",
        16: "y", 17: "t", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        31: "o", 32: "u", 33: "[", 34: "i", 35: "p", 37: "l", 38: "j",
        40: "k", 42: ";", 43: ",", 44: "/", 45: "n", 46: "m", 47: ".",
    ]

    // MARK: - Initialization

    init() {
        setupAudio()
        setupLocalMonitor()
    }

    deinit {
        removeLocalMonitor()
        globalMonitor.stop()
    }

    // MARK: - Audio Setup

    private func setupAudio() {
        do {
            try audioEngine.setup(programs: loadedPrograms)
            audioReady = true
        } catch {
            audioError = error.localizedDescription
            audioReady = false
        }
    }

    // MARK: - Local Keyboard Monitor

    func setupLocalMonitor() {
        removeLocalMonitor()

        localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            [weak self] event in
            // Pass through events with modifier keys (Cmd+Q, Cmd+C, etc.)
            if event.modifierFlags.intersection([.command, .control, .option]).isEmpty == false {
                return event
            }
            guard !event.isARepeat else { return event }
            let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""
            guard let self, self.isMappedKey(chars) else { return event }
            self.handleKeyDown(chars)
            return nil // Swallow only mapped keys to prevent system beep
        }

        localKeyUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp) {
            [weak self] event in
            let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""
            self?.handleKeyUp(chars)
            return event
        }
    }

    private func removeLocalMonitor() {
        if let monitor = localKeyDownMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyDownMonitor = nil
        }
        if let monitor = localKeyUpMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyUpMonitor = nil
        }
    }

    // MARK: - Global Keyboard Monitor

    func enableGlobalMonitor() {
        PermissionManager.ensureInputMonitoring()
        globalMonitor.onKeyDown = { [weak self] keyCode in
            guard let self else { return }
            let char = Self.keyCodeToChar[UInt16(keyCode)] ?? ""
            Task { @MainActor in
                self.handleKeyDown(char)
            }
        }
        globalMonitor.onKeyUp = { [weak self] keyCode in
            guard let self else { return }
            let char = Self.keyCodeToChar[UInt16(keyCode)] ?? ""
            Task { @MainActor in
                self.handleKeyUp(char)
            }
        }
        globalMonitor.start()
        useGlobalMonitor = true
    }

    func disableGlobalMonitor() {
        globalMonitor.stop()
        useGlobalMonitor = false
    }

    // MARK: - Key Handling

    /// Returns true if the character is mapped to a note in the current mode.
    func isMappedKey(_ chars: String) -> Bool {
        switch keyMappingMode {
        case .sequential:
            return currentNoteIndex < score.count
        case .mapped:
            return keyMappings[chars] != nil
        }
    }

    func handleKeyDown(_ chars: String) {
        guard !chars.isEmpty, audioReady else { return }
        activeKeys.insert(chars)

        switch keyMappingMode {
        case .sequential:
            guard currentNoteIndex < score.count else { return }
            let note = score[currentNoteIndex]
            currentNoteIndex += 1
            if !note.isRest {
                audioEngine.playNote(note.midiNote, velocity: note.velocity)
            }

        case .mapped:
            if let midi = keyMappings[chars] {
                audioEngine.playNote(midi)
            }
        }
    }

    func handleKeyUp(_ chars: String) {
        activeKeys.remove(chars)
        guard audioReady else { return }

        if keyMappingMode == .mapped, let midi = keyMappings[chars] {
            audioEngine.stopNote(midi)
        }
    }

    // MARK: - Instrument Switching

    func switchInstrument(to index: Int) {
        guard index < loadedPrograms.count else { return }
        selectedInstrumentIndex = index
        audioEngine.switchInstrument(to: loadedPrograms[index])
    }

    // MARK: - Score Management

    func loadJianpu() {
        let keyMidi = JianpuParser.keys[jianpuKeyIndex].midi
        let parser = JianpuParser(key: keyMidi, tempo: jianpuTempo)
        score = parser.parse(jianpuText)
        currentNoteIndex = 0
    }

    func loadMusicXML(url: URL) {
        let parser = MusicXMLParser()
        score = parser.parse(url: url)
        currentNoteIndex = 0
    }

    func loadMIDIFile(url: URL) {
        let parser = MIDIFileParser(tempo: jianpuTempo)
        score = parser.parse(url: url)
        currentNoteIndex = 0
    }

    func resetPlayback() {
        currentNoteIndex = 0
        audioEngine.stopAllNotes()
    }
}
