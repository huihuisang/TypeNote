import AVFoundation
import AudioToolbox

/// Multi-sampler audio player with pre-loaded instruments for instant switching.
/// Each instrument gets its own AVAudioUnitSampler instance, all connected to the same engine.
final class MultiSamplerPlayer {
    private let engine = AVAudioEngine()
    private var samplers: [UInt8: AVAudioUnitSampler] = [:]
    private(set) var activeProgram: UInt8 = 0
    private(set) var isReady = false

    /// Initialize with a list of GM program numbers to pre-load.
    func setup(programs: [UInt8]) throws {
        guard let soundFontURL = SoundFontPlayer.soundFontURL() else {
            throw SoundFontError.fileNotFound
        }
        try setup(soundFontURL: soundFontURL, programs: programs)
    }

    /// Initialize with an explicit SoundFont URL and program list.
    func setup(soundFontURL: URL, programs: [UInt8]) throws {
        // Clean up any existing samplers
        for (_, sampler) in samplers {
            engine.disconnectNodeOutput(sampler)
            engine.detach(sampler)
        }
        samplers.removeAll()

        for program in programs {
            let sampler = AVAudioUnitSampler()
            engine.attach(sampler)
            engine.connect(sampler, to: engine.mainMixerNode, format: nil)
            try sampler.loadSoundBankInstrument(
                at: soundFontURL,
                program: program,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB)
            )
            samplers[program] = sampler
        }

        setBufferSize(256)

        if !engine.isRunning {
            try engine.start()
        }

        if let first = programs.first {
            activeProgram = first
        }
        isReady = true
    }

    /// Play a MIDI note on the currently active instrument.
    func playNote(_ note: UInt8, velocity: UInt8 = 90) {
        samplers[activeProgram]?.startNote(note, withVelocity: velocity, onChannel: 0)
    }

    /// Stop a specific MIDI note.
    func stopNote(_ note: UInt8) {
        samplers[activeProgram]?.stopNote(note, onChannel: 0)
    }

    /// Stop all sounding notes on the active instrument.
    func stopAllNotes() {
        guard let sampler = samplers[activeProgram] else { return }
        for note: UInt8 in 0...127 {
            sampler.stopNote(note, onChannel: 0)
        }
    }

    /// Switch to a different pre-loaded instrument. Instant, zero latency.
    func switchInstrument(to program: UInt8) {
        guard samplers[program] != nil else { return }
        stopAllNotes()
        activeProgram = program
    }

    /// Dynamically load a new instrument if not already loaded.
    func loadInstrumentIfNeeded(program: UInt8) throws {
        guard samplers[program] == nil else { return }
        guard let soundFontURL = SoundFontPlayer.soundFontURL() else {
            throw SoundFontError.fileNotFound
        }
        let sampler = AVAudioUnitSampler()
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        try sampler.loadSoundBankInstrument(
            at: soundFontURL,
            program: program,
            bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
            bankLSB: UInt8(kAUSampler_DefaultBankLSB)
        )
        samplers[program] = sampler
    }

    // MARK: - Private

    private func setBufferSize(_ frameSize: UInt32) {
        guard let audioUnit = engine.outputNode.audioUnit else { return }
        var size = frameSize
        AudioUnitSetProperty(
            audioUnit,
            kAudioDevicePropertyBufferFrameSize,
            kAudioUnitScope_Global,
            0,
            &size,
            UInt32(MemoryLayout<UInt32>.size)
        )
    }
}
