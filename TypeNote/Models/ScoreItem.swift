import Foundation
import SwiftUI

/// Represents a cached score in the library.
struct ScoreItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: ScoreType
    var createdAt: Date

    /// Tempo in beats per minute (applies to all score types)
    var bpm: Double?

    // Jianpu-specific fields
    var jianpuText: String?
    var jianpuKeyIndex: Int?

    /// GM program number to auto-select when this score is loaded (nil = keep current)
    var instrumentProgram: UInt8?

    // File-based scores: relative filename in cache directory
    var cachedFileName: String?

    init(name: String, type: ScoreType) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.createdAt = Date()
        self.bpm = 120
    }

    // Backward compatibility: migrate jianpuTempo → bpm
    enum CodingKeys: String, CodingKey {
        case id, name, type, createdAt, bpm, jianpuText, jianpuKeyIndex, cachedFileName, instrumentProgram
        case jianpuTempo // legacy key
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        type = try c.decode(ScoreType.self, forKey: .type)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        jianpuText = try c.decodeIfPresent(String.self, forKey: .jianpuText)
        jianpuKeyIndex = try c.decodeIfPresent(Int.self, forKey: .jianpuKeyIndex)
        instrumentProgram = try c.decodeIfPresent(UInt8.self, forKey: .instrumentProgram)
        cachedFileName = try c.decodeIfPresent(String.self, forKey: .cachedFileName)
        // Prefer bpm; fall back to legacy jianpuTempo; default 120
        bpm = try c.decodeIfPresent(Double.self, forKey: .bpm)
            ?? c.decodeIfPresent(Double.self, forKey: .jianpuTempo)
            ?? 120
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(type, forKey: .type)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(bpm, forKey: .bpm)
        try c.encodeIfPresent(jianpuText, forKey: .jianpuText)
        try c.encodeIfPresent(jianpuKeyIndex, forKey: .jianpuKeyIndex)
        try c.encodeIfPresent(instrumentProgram, forKey: .instrumentProgram)
        try c.encodeIfPresent(cachedFileName, forKey: .cachedFileName)
    }

    /// Short preview text for display in grid
    var preview: String {
        switch type {
        case .jianpu:
            let text = jianpuText ?? ""
            return String(text.prefix(60))
        case .musicXML:
            return "MusicXML"
        case .midi:
            return "MIDI"
        }
    }

    var iconName: String {
        switch type {
        case .jianpu: return "number"
        case .musicXML: return "doc.text"
        case .midi: return "pianokeys"
        }
    }

    /// Display label for score type (English, used as localization key)
    var typeLabel: String {
        switch type {
        case .jianpu: return "NUMBERED"
        case .musicXML: return "XML"
        case .midi: return "MIDI"
        }
    }

    /// Localized display label for score type.
    var localizedTypeLabel: LocalizedStringKey { LocalizedStringKey(typeLabel) }
}

enum ScoreType: String, Codable {
    case jianpu
    case musicXML
    case midi
}
