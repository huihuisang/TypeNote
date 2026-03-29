import AVFoundation
import AudioToolbox

/// Single-sampler audio player that loads a SoundFont and plays MIDI notes.
final class SoundFontPlayer {
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()

    init() throws {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        setBufferSize(256)
        try engine.start()
        try loadDefaultInstrument()
    }

    /// Load a General MIDI instrument from the bundled SoundFont.
    /// - Parameter program: GM program number (0 = Grand Piano, 24 = Nylon Guitar, etc.)
    func loadInstrument(program: UInt8) throws {
        guard let url = Self.soundFontURL() else {
            throw SoundFontError.fileNotFound
        }
        try sampler.loadSoundBankInstrument(
            at: url,
            program: program,
            bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
            bankLSB: UInt8(kAUSampler_DefaultBankLSB)
        )
    }

    func playNote(_ note: UInt8, velocity: UInt8 = 90) {
        sampler.startNote(note, withVelocity: velocity, onChannel: 0)
    }

    func stopNote(_ note: UInt8) {
        sampler.stopNote(note, onChannel: 0)
    }

    func stopAllNotes() {
        for note: UInt8 in 0...127 {
            sampler.stopNote(note, onChannel: 0)
        }
    }

    // MARK: - Private

    private func loadDefaultInstrument() throws {
        try loadInstrument(program: 0) // Grand Piano
    }

    /// Set the audio buffer size for low latency.
    /// 256 frames ≈ 5.8ms at 44.1kHz sample rate.
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

    /// Locate the SoundFont file in the app bundle.
    static func soundFontURL() -> URL? {
        // Try multiple common SoundFont names
        let names = ["GeneralUser GS", "GeneralUser_GS", "GeneralUserGS", "soundfont"]
        for name in names {
            if let url = Bundle.main.url(forResource: name, withExtension: "sf2") {
                return url
            }
        }
        return nil
    }
}

enum SoundFontError: LocalizedError {
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "SoundFont file not found. Please add a .sf2 file to the app bundle."
        }
    }
}
