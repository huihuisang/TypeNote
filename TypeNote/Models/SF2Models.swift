import AudioToolbox
import Foundation

// MARK: - SF2Preset

/// A single preset (instrument) within an SF2 SoundFont file.
struct SF2Preset: Identifiable, Codable, Equatable, Hashable {
    let name: String
    let bank: UInt16    // SF2 bank number (0 = GM melodic, 128 = GM percussion)
    let program: UInt8  // MIDI program number (0–127)

    var id: String { "\(bank)-\(program)" }

    /// Subtitle shown in the instrument card, e.g. "Bank 0 · 001"
    var subtitle: String { "Bank \(bank) · \(program + 1)" }

    /// bankMSB / bankLSB values to pass to AVAudioUnitSampler.loadSoundBankInstrument
    var midiBank: (MSB: UInt8, LSB: UInt8) {
        switch bank {
        case 0:   return (UInt8(kAUSampler_DefaultMelodicBankMSB), UInt8(kAUSampler_DefaultBankLSB))
        case 128: return (UInt8(kAUSampler_DefaultPercussionBankMSB), UInt8(kAUSampler_DefaultBankLSB))
        default:  return (0x00, UInt8(bank & 0x7F))
        }
    }
}

// MARK: - SoundFont

/// An imported SF2 SoundFont file together with its parsed preset list.
struct SoundFont: Identifiable, Codable, Equatable {
    let id: UUID
    var displayName: String
    let fileName: String    // filename within Application Support/.../SoundFonts/
    var presets: [SF2Preset]

    init(id: UUID = UUID(), displayName: String, fileName: String, presets: [SF2Preset]) {
        self.id = id
        self.displayName = displayName
        self.fileName = fileName
        self.presets = presets
    }
}

// MARK: - InstrumentRef

/// Identifies the currently active instrument — either a built-in GM program or a custom SF2 preset.
enum InstrumentRef: Equatable, Hashable {
    case gm(program: UInt8)
    case sf2(sf2ID: UUID, preset: SF2Preset)
}
