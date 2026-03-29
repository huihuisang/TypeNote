import SwiftUI
import UniformTypeIdentifiers

/// Panel for loading scores from Jianpu text, MusicXML, or MIDI files.
struct ScoreInputView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tab picker
            Picker("Source", selection: $selectedTab) {
                Text("Jianpu").tag(0)
                Text("MusicXML").tag(1)
                Text("MIDI").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            switch selectedTab {
            case 0:
                JianpuInputView()
            case 1:
                FileImportView(
                    title: "Import MusicXML File",
                    fileTypes: [.xml,
                                UTType(filenameExtension: "musicxml") ?? .xml,
                                UTType(filenameExtension: "mxl") ?? .xml],
                    onImport: { url in appState.loadMusicXML(url: url) }
                )
            case 2:
                FileImportView(
                    title: "Import MIDI File",
                    fileTypes: [UTType(filenameExtension: "mid") ?? .data,
                                UTType(filenameExtension: "midi") ?? .data],
                    onImport: { url in appState.loadMIDIFile(url: url) }
                )
            default:
                EmptyView()
            }

            Divider()

            // Score preview
            ScorePreview()
        }
    }
}

// MARK: - Jianpu Input

struct JianpuInputView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Key selection
                Picker("Key", selection: $state.jianpuKeyIndex) {
                    ForEach(Array(JianpuParser.keys.enumerated()), id: \.offset) { index, key in
                        Text(key.name).tag(index)
                    }
                }
                .frame(width: 120)

                // Tempo
                HStack(spacing: 4) {
                    Text("BPM:")
                        .font(.caption)
                    TextField("BPM", value: $state.jianpuTempo, format: .number)
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                }
            }

            // Jianpu text input
            TextEditor(text: $state.jianpuText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 80)
                .border(Color.gray.opacity(0.3))

            HStack {
                Text("Syntax: 1-7=notes, 0=rest, '=up octave, ,=down, _=half duration, -=extend, #/b=sharp/flat")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button("Load") {
                    appState.loadJianpu()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// MARK: - File Import

struct FileImportView: View {
    let title: String
    let fileTypes: [UTType]
    let onImport: (URL) -> Void

    @State private var showFileImporter = false
    @State private var fileName: String?

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            if let fileName {
                Text("Loaded: \(fileName)")
                    .font(.callout)
                    .foregroundStyle(.green)
            }

            Button("Choose File...") {
                showFileImporter = true
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: fileTypes,
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                fileName = url.lastPathComponent
                onImport(url)
            }
        }
    }
}

// MARK: - Score Preview

struct ScorePreview: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Score Preview")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text("(\(appState.score.count) notes)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if appState.score.isEmpty {
                Text("No score loaded. Enter Jianpu text or import a file.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 2) {
                        ForEach(Array(appState.score.enumerated()), id: \.offset) { index, note in
                            NoteCell(
                                note: note,
                                isCurrent: index == appState.currentNoteIndex,
                                isPlayed: index < appState.currentNoteIndex
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .frame(height: 50)
            }
        }
    }
}

struct NoteCell: View {
    let note: MusicNote
    let isCurrent: Bool
    let isPlayed: Bool

    var body: some View {
        Text(note.noteName)
            .font(.system(.caption2, design: .monospaced))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(isCurrent ? Color.blue.opacity(0.3) :
                            isPlayed ? Color.green.opacity(0.15) :
                            Color.gray.opacity(0.1))
            )
            .foregroundStyle(isCurrent ? .blue : isPlayed ? .green : .primary)
    }
}
