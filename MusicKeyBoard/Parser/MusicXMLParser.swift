import Foundation

/// Parses MusicXML files into MusicNote arrays.
/// Supports standard MusicXML exported by MuseScore, Sibelius, Finale, etc.
class MusicXMLParser: NSObject, XMLParserDelegate {
    private var notes: [MusicNote] = []
    private var divisions = 1
    private var tempo = 120.0

    // Current parsing state
    private var currentElement = ""
    private var currentText = ""
    private var inNote = false
    private var inPitch = false
    private var inDirection = false
    private var inSound = false
    private var isRest = false
    private var step = "C"
    private var alter = 0
    private var octave = 4
    private var duration = 0

    /// Parse a MusicXML file at the given URL.
    func parse(url: URL) -> [MusicNote] {
        notes = []
        divisions = 1
        tempo = 120.0

        guard let data = try? Data(contentsOf: url) else { return [] }
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return notes
    }

    /// Parse MusicXML from a string.
    func parse(string: String) -> [MusicNote] {
        notes = []
        divisions = 1
        tempo = 120.0

        guard let data = string.data(using: .utf8) else { return [] }
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return notes
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        currentElement = elementName
        currentText = ""

        switch elementName {
        case "note":
            inNote = true
            isRest = false
            step = "C"
            alter = 0
            octave = 4
            duration = 0
        case "pitch":
            inPitch = true
        case "rest":
            isRest = true
        case "direction":
            inDirection = true
        case "sound":
            // MusicXML stores tempo in <sound tempo="120"/> within <direction>
            if let tempoStr = attributes["tempo"],
               let parsedTempo = Double(tempoStr), parsedTempo > 0 {
                tempo = parsedTempo
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName: String?) {
        switch elementName {
        case "divisions":
            divisions = max(1, Int(currentText) ?? 1)
        case "step":
            if inPitch { step = currentText }
        case "alter":
            if inPitch { alter = Int(currentText) ?? 0 }
        case "octave":
            if inPitch { octave = Int(currentText) ?? 4 }
        case "duration":
            if inNote { duration = Int(currentText) ?? 0 }
        case "per-minute":
            // Also handle <per-minute>120</per-minute> inside <metronome>
            if let parsedTempo = Double(currentText), parsedTempo > 0 {
                tempo = parsedTempo
            }
        case "pitch":
            inPitch = false
        case "direction":
            inDirection = false
        case "note":
            let seconds = Double(duration) / Double(divisions) * (60.0 / tempo)

            if isRest {
                notes.append(.rest(duration: seconds))
            } else {
                let semitones: [String: Int] = [
                    "C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11
                ]
                let midi = (octave + 1) * 12 + (semitones[step] ?? 0) + alter
                let clampedMidi = min(127, max(0, midi))
                notes.append(.note(UInt8(clampedMidi), duration: seconds))
            }
            inNote = false
        default:
            break
        }
    }
}
