import ServiceManagement
import SwiftUI

/// Menu bar popover: score status, instrument picker, and library entry.
struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                header
                Divider()
                instrumentSection
                Divider()
                scoreSection
                Divider()
                playModePicker
                Divider()
                playbackOptions
                Divider()
                footer
            }
            .padding(16)
            .frame(width: 320)

            if !PermissionManager.hasInputMonitoring {
                permissionOverlay
            }
        }
    }

    // MARK: - Permission Overlay

    private var permissionOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            VStack(spacing: 16) {
                Image(systemName: "keyboard")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text("Permission Required")
                    .font(.headline)

                Text("Input Monitoring is needed to\ndetect keyboard events.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    openOnboarding()
                } label: {
                    Label("Grant Permission", systemImage: "lock.open")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 24)
            }

            // Quit button at bottom-right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(12)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "pianokeys")
                .font(.title2)
            Text("TypeNote")
                .font(.headline)
            Spacer()
            Toggle("", isOn: Binding(
                get: { appState.isEnabled },
                set: { appState.isEnabled = $0 }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
    }

    // MARK: - Score

    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Score")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.scoreName)
                        .font(.body.bold())
                    Text("\(appState.currentNoteIndex)/\(appState.score.count) notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button { appState.resetPlayback() } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.borderless)
                .help("Reset to beginning")
            }

            if !appState.score.isEmpty {
                ProgressView(
                    value: Double(appState.currentNoteIndex),
                    total: Double(appState.score.count)
                )
            }

            Button {
                openLibraryWindow()
            } label: {
                Label("Library", systemImage: "music.note.list")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var playModePicker: some View {
        @Bindable var state = appState

        return VStack(alignment: .leading, spacing: 4) {
            Text("Play Mode")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(PlayMode.allCases, id: \.self) { mode in
                Button {
                    state.playMode = mode
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: mode == state.playMode ? "checkmark" : "")
                            .font(.caption2.weight(.semibold))
                            .frame(width: 14)
                        Image(systemName: mode.iconName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Text(mode.label)
                            .font(.callout)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Instrument

    private var instrumentSection: some View {
        @Bindable var state = appState

        return VStack(alignment: .leading, spacing: 8) {
            Text("Instrument")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: "pianokeys")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(appState.selectedInstrumentName)
                    .font(.callout)
                Spacer()
            }

            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 14)
                Slider(value: $state.instrumentVolume, in: 0 ... 1)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
            }
        }
    }

    // MARK: - Playback Options

    private var playbackOptions: some View {
        @Bindable var state = appState

        return VStack(alignment: .leading, spacing: 8) {
            Text("Options")
                .font(.caption)
                .foregroundStyle(.secondary)

            LaunchAtLoginToggle()

            Toggle("Non-Interrupt Mode", isOn: $state.nonInterruptMode)
                .font(.callout)
                .help("Wait for current note to finish before playing the next one")

            Text("When on, each note plays fully before the next key takes effect")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if let error = appState.audioError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Circle()
                    .fill(appState.isEnabled ? .green : .gray)
                    .frame(width: 6, height: 6)
                Text(appState.isEnabled ? "Press any key to play" : "Paused")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("About") {
                openAboutWindow()
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .foregroundStyle(.secondary)
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func openAboutWindow() {
        dismiss()
        NSApp.setActivationPolicy(.regular)
        openWindow(id: "about")
        NSApp.activate(ignoringOtherApps: true)
    }

    private func openLibraryWindow() {
        dismiss()
        NSApp.setActivationPolicy(.regular)
        openWindow(id: "library")
        NSApp.activate(ignoringOtherApps: true)
    }

    private func openOnboarding() {
        NSApp.setActivationPolicy(.regular)
        openWindow(id: "onboarding")
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Launch at Login Toggle

/// Toggle that registers/unregisters the app as a login item via SMAppService.
private struct LaunchAtLoginToggle: View {
    @State private var isEnabled = SMAppService.mainApp.status == .enabled

    var body: some View {
        Toggle("Launch at Login", isOn: Binding(
            get: { isEnabled },
            set: { newValue in
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                    isEnabled = SMAppService.mainApp.status == .enabled
                } catch {
                    // Registration may fail if the user has blocked it in System Settings
                    isEnabled = SMAppService.mainApp.status == .enabled
                }
            }
        ))
        .font(.callout)
    }
}

#Preview {
    MenuBarView()
        .environment(AppState())
}
