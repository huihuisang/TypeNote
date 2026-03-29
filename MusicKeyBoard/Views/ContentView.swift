import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar
            ToolbarSection()
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()

            // Main content
            HSplitView {
                // Left: Score input
                ScoreInputView()
                    .frame(minWidth: 300)

                // Right: Keyboard & status
                VStack(spacing: 16) {
                    if let error = appState.audioError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text(error)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }

                    // Playback status
                    if appState.keyMappingMode == .sequential && !appState.score.isEmpty {
                        PlaybackStatusView()
                    }

                    Spacer()

                    // Virtual keyboard
                    KeyboardView()
                        .padding(.bottom, 20)
                }
                .frame(minWidth: 500)
                .padding()
            }
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}

// MARK: - Toolbar

struct ToolbarSection: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        HStack(spacing: 16) {
            // Instrument picker
            Picker("Instrument", selection: $state.selectedInstrumentIndex) {
                ForEach(Array(appState.loadedPrograms.enumerated()), id: \.offset) { index, program in
                    let name = KeyMapping.instruments.first(where: { $0.program == program })?.name ?? "Program \(program)"
                    Text(name).tag(index)
                }
            }
            .frame(width: 220)
            .onChange(of: appState.selectedInstrumentIndex) { _, newValue in
                appState.switchInstrument(to: newValue)
            }

            Divider().frame(height: 20)

            // Mode picker
            Picker("Mode", selection: $state.keyMappingMode) {
                Text("Piano Keys").tag(KeyMappingMode.mapped)
                Text("Sequential").tag(KeyMappingMode.sequential)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            Spacer()

            // Audio status indicator
            Circle()
                .fill(appState.audioReady ? .green : .red)
                .frame(width: 8, height: 8)
            Text(appState.audioReady ? "Ready" : "No Audio")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Playback Status

struct PlaybackStatusView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 12) {
            // Progress
            Text("\(appState.currentNoteIndex) / \(appState.score.count)")
                .font(.title2.monospacedDigit())
                .foregroundStyle(.primary)

            ProgressView(value: Double(appState.currentNoteIndex),
                         total: Double(max(1, appState.score.count)))
                .frame(width: 200)

            // Current note info
            if appState.currentNoteIndex < appState.score.count {
                let note = appState.score[appState.currentNoteIndex]
                Text("Next: \(note.noteName)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Text("Complete!")
                    .font(.callout)
                    .foregroundStyle(.green)
            }

            Spacer()

            // Reset button
            Button("Reset") {
                appState.resetPlayback()
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
    }
}
