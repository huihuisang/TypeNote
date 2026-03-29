import SwiftUI

/// App settings panel accessible via Cmd+, or the Settings menu.
struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }

            KeyMappingSettingsView()
                .tabItem { Label("Key Mapping", systemImage: "keyboard") }

            PermissionsSettingsView()
                .tabItem { Label("Permissions", systemImage: "lock.shield") }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        Form {
            Section("Audio") {
                HStack {
                    Text("Status")
                    Spacer()
                    if appState.audioReady {
                        Label("Ready", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label(appState.audioError ?? "Not Ready", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }

                Picker("Default Instrument", selection: $state.selectedInstrumentIndex) {
                    ForEach(Array(appState.loadedPrograms.enumerated()), id: \.offset) { index, program in
                        let name = KeyMapping.instruments.first(where: { $0.program == program })?.name ?? "Program \(program)"
                        Text(name).tag(index)
                    }
                }
                .onChange(of: appState.selectedInstrumentIndex) { _, newValue in
                    appState.switchInstrument(to: newValue)
                }
            }

            Section("Playback") {
                Picker("Input Mode", selection: $state.keyMappingMode) {
                    Text("Piano Keys (Mapped)").tag(KeyMappingMode.mapped)
                    Text("Sequential (Score)").tag(KeyMappingMode.sequential)
                }

                HStack {
                    Text("Default Tempo")
                    Spacer()
                    TextField("BPM", value: $state.jianpuTempo, format: .number)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                    Text("BPM")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Key Mapping Settings

struct KeyMappingSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Key Mapping")
                .font(.headline)

            Text("Default DAW piano layout: Home row = white keys, upper row = black keys")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Sort by MIDI note for display
            let sortedMappings = appState.keyMappings.sorted { $0.value < $1.value }

            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 8) {
                    ForEach(sortedMappings, id: \.key) { key, midi in
                        HStack {
                            Text(key.uppercased())
                                .font(.system(.body, design: .monospaced, weight: .bold))
                                .frame(width: 24)
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(midiToNoteName(midi))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                    }
                }
            }

            HStack {
                Spacer()
                Button("Reset to Default") {
                    appState.keyMappings = KeyMapping.defaultPianoLayout
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private func midiToNoteName(_ midi: UInt8) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(midi) / 12 - 1
        return "\(names[Int(midi) % 12])\(octave)"
    }
}

// MARK: - Permissions Settings

struct PermissionsSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            Section("Keyboard Monitoring") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Local Monitoring")
                            .font(.body)
                        Text("Works when the app is in the foreground. No permissions required.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Global Monitoring")
                            .font(.body)
                        Text("Works even when the app is in the background. Requires Input Monitoring permission.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { appState.useGlobalMonitor },
                        set: { enabled in
                            if enabled {
                                appState.enableGlobalMonitor()
                            } else {
                                appState.disableGlobalMonitor()
                            }
                        }
                    ))
                }
            }

            Section("About Permissions") {
                Text("Input Monitoring: Required for global keyboard monitoring (CGEventTap). The app uses listen-only mode and never intercepts or modifies your keystrokes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Note: Keyboard events cannot be captured in password fields or other secure input areas. This is a macOS security feature.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
