import Foundation
import AudioToolbox

/// Parses standard MIDI files into MusicNote arrays using AudioToolbox.
/// Falls back to basic parsing if MidiParser SPM package is not available.
struct MIDIFileParser {
    let tempo: Double

    init(tempo: Double = 120.0) {
        self.tempo = tempo
    }

    /// Parse a MIDI file at the given URL using AudioToolbox.
    func parse(url: URL) -> [MusicNote] {
        var musicSequence: MusicSequence?
        guard NewMusicSequence(&musicSequence) == noErr,
              let sequence = musicSequence else { return [] }

        defer { DisposeMusicSequence(sequence) }

        guard MusicSequenceFileLoad(sequence, url as CFURL,
                                     .midiType, .smf_ChannelsToTracks) == noErr
        else { return [] }

        var trackCount: UInt32 = 0
        guard MusicSequenceGetTrackCount(sequence, &trackCount) == noErr,
              trackCount > 0 else { return [] }

        var notes: [MusicNote] = []

        // Iterate through all tracks
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
                   let data = eventData {
                    let noteMessage = data.load(as: MIDINoteMessage.self)
                    let durationSeconds = Double(noteMessage.duration) * (60.0 / tempo)
                    notes.append(.note(
                        UInt8(noteMessage.note),
                        duration: durationSeconds,
                        velocity: UInt8(noteMessage.velocity)
                    ))
                }

                MusicEventIteratorNextEvent(eventIterator)
                MusicEventIteratorHasCurrentEvent(eventIterator, &hasNext)
            }
        }

        return notes
    }
}
