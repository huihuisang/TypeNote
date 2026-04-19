import AVFoundation
import AudioToolbox
import Foundation

/// Multi-sampler audio player with pre-loaded instruments for instant switching.
///
/// GM instruments each get their own `AVAudioUnitSampler` for zero-latency switching.
/// Custom SF2 presets share a single dedicated sampler that is loaded on demand.
@MainActor
final class MultiSamplerPlayer {
    private struct CustomPresetState {
        let sf2URL: URL
        let preset: SF2Preset
    }

    private struct EngineSnapshot {
        let soundFontURL: URL
        let loadedPrograms: [UInt8]
        let activeProgram: UInt8
        let isCustomActive: Bool
        let customPresetState: CustomPresetState?
        let volume: Float
    }

    private var engine = AVAudioEngine()
    private var engineConfigurationObserver: NSObjectProtocol?
    private let outputDeviceListenerQueue = DispatchQueue(label: "TypeNote.Audio.OutputDeviceListener")
    private var outputDeviceObserverInstalled = false
    private lazy var outputDeviceListener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
        guard let self else { return }
        DispatchQueue.main.async {
            guard !self.isRebuilding else { return }
            self.onConfigurationChange?()
        }
    }
    private var outputDeviceAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    // One sampler per GM program, keyed by program number.
    private var samplers: [UInt8: AVAudioUnitSampler] = [:]
    private(set) var activeProgram: UInt8 = 0

    // Single sampler reused for all custom SF2 presets.
    private var customSampler: AVAudioUnitSampler?
    private var customPresetState: CustomPresetState?
    private(set) var isCustomActive = false
    private var currentSoundFontURL: URL?
    private var masterVolume: Float = 1.0
    private var isRebuilding = false

    private let preferredBufferFrameSize: UInt32 = 256

    private(set) var isReady = false
    var onConfigurationChange: (() -> Void)?

    init() {
        installOutputDeviceObserver()
        installEngineConfigurationObserver(for: engine)
    }

    deinit {
        MainActor.assumeIsolated {
            removeEngineConfigurationObserver()
            removeOutputDeviceObserver()
            engine.stop()
        }
    }

    // MARK: - Setup

    /// Initialize with a list of GM program numbers to pre-load from the bundled SoundFont.
    func setup(programs: [UInt8]) throws {
        guard let soundFontURL = SoundFontPlayer.soundFontURL() else {
            throw SoundFontError.fileNotFound
        }
        try setup(soundFontURL: soundFontURL, programs: programs)
    }

    /// Initialize with an explicit SoundFont URL and program list.
    func setup(soundFontURL: URL, programs: [UInt8]) throws {
        let programsToLoad = uniquePrograms(from: programs)
        let initialProgram = programsToLoad.first ?? activeProgram
        let snapshot = EngineSnapshot(
            soundFontURL: soundFontURL,
            loadedPrograms: programsToLoad,
            activeProgram: initialProgram,
            isCustomActive: false,
            customPresetState: nil,
            volume: masterVolume
        )
        try rebuildEngine(using: snapshot)
    }

    /// Rebuild the engine after the system output device changes.
    func rebuildAfterOutputDeviceChange() throws {
        guard isReady else { return }
        try rebuildEngine(using: makeSnapshot())
    }

    // MARK: - GM Instrument Control

    /// Play a MIDI note on the currently active instrument.
    func playNote(_ note: UInt8, velocity: UInt8 = 90) {
        guard !isRebuilding else { return }
        activeSampler?.startNote(note, withVelocity: velocity, onChannel: 0)
    }

    /// Stop a specific MIDI note on the active instrument.
    func stopNote(_ note: UInt8) {
        guard !isRebuilding else { return }
        activeSampler?.stopNote(note, onChannel: 0)
    }

    /// Stop all 128 notes on the active instrument.
    func stopAllNotes() {
        guard !isRebuilding, let sampler = activeSampler else { return }
        for note: UInt8 in 0 ... 127 {
            sampler.stopNote(note, onChannel: 0)
        }
    }

    /// Switch to a different pre-loaded GM instrument. Instant, zero latency.
    func switchInstrument(to program: UInt8) {
        guard !isRebuilding, samplers[program] != nil else { return }
        stopAllNotes()
        activeProgram = program
        isCustomActive = false
    }

    /// Check if a GM program is already loaded.
    func isLoaded(_ program: UInt8) -> Bool {
        samplers[program] != nil
    }

    /// Dynamically load a GM instrument if not already in memory.
    func loadInstrumentIfNeeded(program: UInt8) throws {
        guard !isRebuilding, samplers[program] == nil else { return }
        guard let soundFontURL = currentSoundFontURL ?? SoundFontPlayer.soundFontURL() else {
            throw SoundFontError.fileNotFound
        }

        let sampler = AVAudioUnitSampler()
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        try loadGMProgram(program, into: sampler, soundFontURL: soundFontURL)
        samplers[program] = sampler
        currentSoundFontURL = soundFontURL
        try startEngineIfNeeded()
    }

    // MARK: - Custom SF2 Preset Control

    /// Load a preset from a custom SF2 file and make it the active instrument.
    /// The custom sampler is created lazily and reused across preset switches.
    func loadCustomPreset(sf2URL: URL, preset: SF2Preset) throws {
        guard !isRebuilding else { return }

        if customSampler == nil {
            let sampler = AVAudioUnitSampler()
            engine.attach(sampler)
            engine.connect(sampler, to: engine.mainMixerNode, format: nil)
            customSampler = sampler
        }

        stopAllNotes()

        guard let customSampler else { return }
        let bank = preset.midiBank
        try customSampler.loadSoundBankInstrument(
            at: sf2URL,
            program: preset.program,
            bankMSB: bank.MSB,
            bankLSB: bank.LSB
        )
        customPresetState = CustomPresetState(sf2URL: sf2URL, preset: preset)
        isCustomActive = true
        try startEngineIfNeeded()
    }

    // MARK: - Volume

    /// Set the master output volume (0.0 = silent, 1.0 = full).
    func setVolume(_ volume: Float) {
        masterVolume = max(0, min(1, volume))
        engine.mainMixerNode.outputVolume = masterVolume
    }

    // MARK: - Private

    /// The sampler that should receive note events right now.
    private var activeSampler: AVAudioUnitSampler? {
        isCustomActive ? customSampler : samplers[activeProgram]
    }

    private func rebuildEngine(using snapshot: EngineSnapshot) throws {
        guard !isRebuilding else { return }

        isRebuilding = true
        defer { isRebuilding = false }

        stopAllNotesOnAllSamplers()
        tearDownCurrentEngine()

        let newEngine = AVAudioEngine()
        var newSamplers: [UInt8: AVAudioUnitSampler] = [:]

        for program in snapshot.loadedPrograms {
            let sampler = AVAudioUnitSampler()
            newEngine.attach(sampler)
            newEngine.connect(sampler, to: newEngine.mainMixerNode, format: nil)
            try loadGMProgram(program, into: sampler, soundFontURL: snapshot.soundFontURL)
            newSamplers[program] = sampler
        }

        var rebuiltCustomSampler: AVAudioUnitSampler?
        if let customPresetState = snapshot.customPresetState {
            let sampler = AVAudioUnitSampler()
            newEngine.attach(sampler)
            newEngine.connect(sampler, to: newEngine.mainMixerNode, format: nil)

            let bank = customPresetState.preset.midiBank
            try sampler.loadSoundBankInstrument(
                at: customPresetState.sf2URL,
                program: customPresetState.preset.program,
                bankMSB: bank.MSB,
                bankLSB: bank.LSB
            )
            rebuiltCustomSampler = sampler
        }

        newEngine.mainMixerNode.outputVolume = snapshot.volume

        let bufferStatus = setBufferSize(preferredBufferFrameSize, on: newEngine)
        if bufferStatus != noErr {
            print("Failed to set preferred output buffer size: \(bufferStatus)")
        }

        installEngineConfigurationObserver(for: newEngine)
        try newEngine.start()

        engine = newEngine
        samplers = newSamplers
        customSampler = rebuiltCustomSampler
        customPresetState = snapshot.customPresetState
        currentSoundFontURL = snapshot.soundFontURL
        masterVolume = snapshot.volume
        activeProgram = newSamplers[snapshot.activeProgram] != nil
            ? snapshot.activeProgram
            : (snapshot.loadedPrograms.first ?? activeProgram)
        isCustomActive = snapshot.isCustomActive && rebuiltCustomSampler != nil
        isReady = true
    }

    private func makeSnapshot() throws -> EngineSnapshot {
        guard let soundFontURL = currentSoundFontURL ?? SoundFontPlayer.soundFontURL() else {
            throw SoundFontError.fileNotFound
        }
        let loadedPrograms = uniquePrograms(from: samplers.keys.sorted())

        return EngineSnapshot(
            soundFontURL: soundFontURL,
            loadedPrograms: loadedPrograms,
            activeProgram: activeProgram,
            isCustomActive: isCustomActive,
            customPresetState: customPresetState,
            volume: masterVolume
        )
    }

    private func uniquePrograms<S: Sequence>(from programs: S) -> [UInt8] where S.Element == UInt8 {
        var seen = Set<UInt8>()
        return programs.filter { seen.insert($0).inserted }
    }

    private func loadGMProgram(_ program: UInt8, into sampler: AVAudioUnitSampler, soundFontURL: URL) throws {
        try sampler.loadSoundBankInstrument(
            at: soundFontURL,
            program: program,
            bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
            bankLSB: UInt8(kAUSampler_DefaultBankLSB)
        )
    }

    private func startEngineIfNeeded() throws {
        if !engine.isRunning {
            try engine.start()
        }
    }

    private func stopAllNotesOnAllSamplers() {
        let allSamplers = Array(samplers.values) + [customSampler].compactMap { $0 }
        for sampler in allSamplers {
            for note: UInt8 in 0 ... 127 {
                sampler.stopNote(note, onChannel: 0)
            }
        }
    }

    private func tearDownCurrentEngine() {
        removeEngineConfigurationObserver()

        engine.stop()
        engine.reset()

        for sampler in samplers.values {
            engine.disconnectNodeInput(sampler)
            engine.disconnectNodeOutput(sampler)
            engine.detach(sampler)
        }

        if let customSampler {
            engine.disconnectNodeInput(customSampler)
            engine.disconnectNodeOutput(customSampler)
            engine.detach(customSampler)
        }

        samplers.removeAll()
        customSampler = nil
        isReady = false
    }

    private func installEngineConfigurationObserver(for engine: AVAudioEngine) {
        removeEngineConfigurationObserver()
        engineConfigurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                guard !self.isRebuilding else { return }
                self.onConfigurationChange?()
            }
        }
    }

    private func removeEngineConfigurationObserver() {
        if let engineConfigurationObserver {
            NotificationCenter.default.removeObserver(engineConfigurationObserver)
            self.engineConfigurationObserver = nil
        }
    }

    private func installOutputDeviceObserver() {
        guard !outputDeviceObserverInstalled else { return }

        let status = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &outputDeviceAddress,
            outputDeviceListenerQueue,
            outputDeviceListener
        )

        if status == noErr {
            outputDeviceObserverInstalled = true
        } else {
            print("Failed to observe default output device changes: \(status)")
        }
    }

    private func removeOutputDeviceObserver() {
        guard outputDeviceObserverInstalled else { return }

        let status = AudioObjectRemovePropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &outputDeviceAddress,
            outputDeviceListenerQueue,
            outputDeviceListener
        )

        if status != noErr {
            print("Failed to remove output device observer: \(status)")
        }
        outputDeviceObserverInstalled = false
    }

    @discardableResult
    private func setBufferSize(_ frameSize: UInt32, on engine: AVAudioEngine) -> OSStatus {
        guard let audioUnit = engine.outputNode.audioUnit else { return kAudio_ParamError }
        var size = frameSize
        return AudioUnitSetProperty(
            audioUnit,
            kAudioDevicePropertyBufferFrameSize,
            kAudioUnitScope_Global,
            0,
            &size,
            UInt32(MemoryLayout<UInt32>.size)
        )
    }
}
