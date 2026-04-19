import SwiftUI

@main
struct TypeNoteApp: App {
    /// Activated by passing `--screenshot` at launch; enables automated capture mode.
    static let isScreenshotMode = CommandLine.arguments.contains("--screenshot")

    @State private var appState = AppState()
    @StateObject private var updateController = UpdateController()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            Image(systemName: "pianokeys")
                .onAppear {
                    if TypeNoteApp.isScreenshotMode {
                        // Screenshot mode: show dock icon and open Library directly
                        NSApp.setActivationPolicy(.regular)
                        openWindow(id: "library")
                    } else if !PermissionManager.isOnboardingCompleted {
                        // First launch: show dock icon for onboarding window
                        NSApp.setActivationPolicy(.regular)
                        openWindow(id: "onboarding")
                    }
                    // Normal relaunch: stay as .accessory (no dock icon)
                }
        }
        .menuBarExtraStyle(.window)

        Window("Library", id: "library") {
            MainLibraryView()
                .environment(appState)
        }
        .defaultSize(width: 1000, height: 750)
        .defaultPosition(.center)
        .windowResizability(.contentSize)

        Window("About TypeNote", id: "about") {
            AboutView()
                .environmentObject(updateController)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("Welcome", id: "onboarding") {
            OnboardingView {
                appState.restartMonitorIfNeeded()
                NSApp.windows
                    .first { $0.title == "Welcome" }?
                    .close()
            }
            .environment(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

// MARK: - Compatibility

extension Scene {
    /// Apply `.defaultLaunchBehavior(.presented)` on macOS 15+, no-op on older.
    func applyDefaultLaunchBehavior() -> some Scene {
        if #available(macOS 15.0, *) {
            return defaultLaunchBehavior(.presented)
        } else {
            return self
        }
    }
}
