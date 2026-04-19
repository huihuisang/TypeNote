import Foundation

/// Parses preset headers from an SF2 (SoundFont 2) file.
///
/// SF2 is a RIFF-based format. This parser only reads the tiny `pdta/phdr` chunk
/// that holds preset names and locations — it never loads the large sample-data block.
///
/// Reference: SoundFont 2.04 specification, section 5 (RIFF structure) and 7.2 (phdr sub-chunk).
enum SF2Parser {

    // MARK: - Public API

    /// Parse all melodic presets from an SF2 file.
    /// Uses memory-mapped I/O so only the accessed pages are loaded from disk.
    static func parsePresets(from url: URL) -> [SF2Preset] {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return [] }
        return parsePresets(from: data)
    }

    // MARK: - Internal (testable)

    static func parsePresets(from data: Data) -> [SF2Preset] {
        // Validate RIFF / sfbk header
        guard data.count > 12,
              fourCC(data, 0) == "RIFF",
              fourCC(data, 8) == "sfbk" else { return [] }

        // Walk top-level chunks to find the pdta LIST chunk
        guard let pdtaBase = findLIST(named: "pdta", in: data, from: 12, to: data.count) else {
            return []
        }

        // pdta LIST layout:
        //   "LIST" (4) | size (4) | "pdta" (4) | sub-chunks …
        let pdtaSize = Int(u32(data, pdtaBase + 4))
        let subStart = pdtaBase + 12
        let subEnd   = pdtaBase + 8 + pdtaSize

        // Find phdr sub-chunk within pdta
        guard let phdrBase = findChunk(named: "phdr", in: data, from: subStart, to: subEnd) else {
            return []
        }

        let phdrSize = Int(u32(data, phdrBase + 4))
        return readPresetHeaders(data: data, from: phdrBase + 8, size: phdrSize)
    }

    // MARK: - Preset Header Parsing

    /// Each SFPresetHeader is exactly 38 bytes (SF2 spec §7.2).
    private static let phdrStride = 38

    private static func readPresetHeaders(data: Data, from offset: Int, size: Int) -> [SF2Preset] {
        guard size > 0, size % phdrStride == 0 else { return [] }
        var presets: [SF2Preset] = []

        for i in 0 ..< (size / phdrStride) {
            let base = offset + i * phdrStride
            guard base + phdrStride <= data.count else { break }

            // achPresetName: 20 null-padded ASCII bytes at offset 0
            let nameBytes = data[base ..< (base + 20)]
            let name = String(bytes: nameBytes.prefix(while: { $0 != 0 }), encoding: .ascii) ?? ""

            // "EOP" is the mandatory end-of-presets sentinel — skip it
            guard !name.isEmpty, name != "EOP" else { continue }

            // wPreset (u16) at offset 20 = MIDI program number
            // wBank   (u16) at offset 22 = SF2 bank number
            let program = u16(data, base + 20)
            let bank    = u16(data, base + 22)

            presets.append(SF2Preset(
                name:    name,
                bank:    bank,
                program: UInt8(program & 0x7F)
            ))
        }

        // Sort by bank first, then program number
        return presets.sorted {
            $0.bank == $1.bank ? $0.program < $1.program : $0.bank < $1.bank
        }
    }

    // MARK: - RIFF Traversal

    /// Find a LIST chunk whose 4-byte type field matches `name`.
    private static func findLIST(named name: String, in data: Data, from start: Int, to end: Int) -> Int? {
        var offset = start
        while offset + 12 <= end {
            let cc   = fourCC(data, offset)
            let size = Int(u32(data, offset + 4))
            if cc == "LIST", fourCC(data, offset + 8) == name { return offset }
            let next = offset + 8 + size + (size & 1) // RIFF pads chunks to even size
            guard next > offset else { break }
            offset = next
        }
        return nil
    }

    /// Find a plain (non-LIST) chunk whose FourCC matches `name`.
    private static func findChunk(named name: String, in data: Data, from start: Int, to end: Int) -> Int? {
        var offset = start
        while offset + 8 <= end {
            let cc   = fourCC(data, offset)
            let size = Int(u32(data, offset + 4))
            if cc == name { return offset }
            let next = offset + 8 + size + (size & 1)
            guard next > offset else { break }
            offset = next
        }
        return nil
    }

    // MARK: - Byte Helpers (little-endian, native on all Apple platforms)

    private static func fourCC(_ data: Data, _ offset: Int) -> String {
        guard offset + 4 <= data.count else { return "" }
        return String(bytes: data[offset ..< (offset + 4)], encoding: .ascii) ?? ""
    }

    private static func u32(_ data: Data, _ offset: Int) -> UInt32 {
        guard offset + 4 <= data.count else { return 0 }
        return data[offset ..< (offset + 4)].withUnsafeBytes { $0.load(as: UInt32.self) }
    }

    private static func u16(_ data: Data, _ offset: Int) -> UInt16 {
        guard offset + 2 <= data.count else { return 0 }
        return data[offset ..< (offset + 2)].withUnsafeBytes { $0.load(as: UInt16.self) }
    }
}
