import Foundation
import AudioToolbox

/// Parses standard MIDI files into MusicNote arrays using AudioToolbox.
/// Uses inter-onset intervals (time between note starts) for note durations,
/// which better represents rhythmic timing than raw MIDI note sustain durations.
struct MIDIFileParser {
    let tempo: Double
    /// When true, always use the provided tempo instead of detecting from file
    let overrideTempo: Bool

    init(tempo: Double = 120.0, override: Bool = false) {
        self.tempo = tempo
        self.overrideTempo = `override`
    }

    /// Result containing parsed notes and detected BPM.
    struct Result {
        let notes: [MusicNote]
        let bpm: Double
    }

    /// Parse a MIDI file at the given URL using AudioToolbox.
    func parse(url: URL) -> [MusicNote] {
        return parseWithBPM(url: url).notes
    }

    /// Parse and return both notes and detected BPM.
    func parseWithBPM(url: URL) -> Result {
        var musicSequence: MusicSequence?
        guard NewMusicSequence(&musicSequence) == noErr,
              let sequence = musicSequence else { return Result(notes: [], bpm: tempo) }

        defer { DisposeMusicSequence(sequence) }

        guard MusicSequenceFileLoad(sequence, url as CFURL,
                                     .midiType, .smf_ChannelsToTracks) == noErr
        else { return Result(notes: [], bpm: tempo) }

        // Use overridden tempo or detect from file
        let detectedBPM = overrideTempo ? tempo : (extractTempo(from: sequence) ?? tempo)
        let secPerBeat = 60.0 / detectedBPM

        var trackCount: UInt32 = 0
        guard MusicSequenceGetTrackCount(sequence, &trackCount) == noErr,
              trackCount > 0 else { return Result(notes: [], bpm: detectedBPM) }

        // Collect raw note events from all tracks
        var noteEvents: [NoteEvent] = []

        for trackIndex in 0..<trackCount {
            var track: MusicTrack?
            guard MusicSequenceGetIndTrack(sequence, trackIndex, &track) == noErr,
                  let musicTrack = track else { continue }

            var iterator: MusicEventIterator?
            guard NewMusicEventIterator(musicTrack, &iterator) == noErr,
                  let eventIterator = iterator else { continue }

            defer { DisposeMusicEventIterator(eventIterator) }

            var hasNext: DarwinBoolean = true

            while hasNext.boolValue {
                var timestamp: MusicTimeStamp = 0
                var eventType: MusicEventType = 0
                var eventData: UnsafeRawPointer?
                var eventDataSize: UInt32 = 0

                guard MusicEventIteratorGetEventInfo(
                    eventIterator, &timestamp, &eventType,
                    &eventData, &eventDataSize
                ) == noErr else { break }

                if eventType == kMusicEventType_MIDINoteMessage,
                   let data = eventData,
                   eventDataSize >= UInt32(MemoryLayout<MIDINoteMessage>.size) {
                    let msg = data.load(as: MIDINoteMessage.self)
                    noteEvents.append(NoteEvent(
                        timestamp: timestamp,
                        midiNote: UInt8(msg.note),
                        sustainDuration: Double(msg.duration) * secPerBeat,
                        velocity: UInt8(msg.velocity)
                    ))
                }

                MusicEventIteratorNextEvent(eventIterator)
                MusicEventIteratorHasCurrentEvent(eventIterator, &hasNext)
            }
        }

        // Sort by timestamp to get chronological order
        noteEvents.sort { $0.timestamp < $1.timestamp }

        // Convert to MusicNote using inter-onset interval as duration
        let notes = buildNotes(from: noteEvents, secPerBeat: secPerBeat)

        return Result(notes: notes, bpm: detectedBPM)
    }

    // MARK: - Note Building

    /// Intermediate representation for sorting and interval computation.
    private struct NoteEvent {
        let timestamp: MusicTimeStamp  // in beats
        let midiNote: UInt8
        let sustainDuration: Double    // original sustain in seconds
        let velocity: UInt8
    }

    /// Build MusicNote array using inter-onset intervals for durations.
    /// This ensures note duration reflects the rhythmic gap between notes,
    /// not the raw MIDI sustain (which can be much longer due to pedal, etc.)
    private func buildNotes(from events: [NoteEvent], secPerBeat: Double) -> [MusicNote] {
        guard !events.isEmpty else { return [] }

        var notes: [MusicNote] = []
        let minDuration = 0.05 // 50ms floor to avoid zero-length notes

        for i in 0..<events.count {
            let event = events[i]

            // Duration = time until next note starts, capped by sustain duration
            let interOnset: Double
            if i + 1 < events.count {
                interOnset = (events[i + 1].timestamp - event.timestamp) * secPerBeat
            } else {
                // Last note: use sustain duration
                interOnset = event.sustainDuration
            }

            // Use the shorter of inter-onset interval and sustain, with a minimum floor
            let duration = max(minDuration, min(interOnset, event.sustainDuration))

            notes.append(.note(
                event.midiNote,
                duration: duration,
                velocity: event.velocity
            ))
        }

        return notes
    }

    // MARK: - Tempo Extraction

    /// Extract the first tempo event from the MIDI tempo track.
    private func extractTempo(from sequence: MusicSequence) -> Double? {
        var tempoTrack: MusicTrack?
        guard MusicSequenceGetTempoTrack(sequence, &tempoTrack) == noErr,
              let track = tempoTrack else { return nil }

        var iterator: MusicEventIterator?
        guard NewMusicEventIterator(track, &iterator) == noErr,
              let eventIterator = iterator else { return nil }

        defer { DisposeMusicEventIterator(eventIterator) }

        var hasNext: DarwinBoolean = true

        while hasNext.boolValue {
            var timestamp: MusicTimeStamp = 0
            var eventType: MusicEventType = 0
            var eventData: UnsafeRawPointer?
            var eventDataSize: UInt32 = 0

            guard MusicEventIteratorGetEventInfo(
                eventIterator, &timestamp, &eventType,
                &eventData, &eventDataSize
            ) == noErr else { break }

            // kMusicEventType_ExtendedTempo contains BPM as Float64
            if eventType == kMusicEventType_ExtendedTempo,
               let data = eventData {
                let bpm = data.load(as: ExtendedTempoEvent.self).bpm
                if bpm > 0 { return bpm }
            }

            MusicEventIteratorNextEvent(eventIterator)
            MusicEventIteratorHasCurrentEvent(eventIterator, &hasNext)
        }

        return nil
    }
}
