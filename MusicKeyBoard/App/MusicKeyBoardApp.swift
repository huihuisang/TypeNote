import SwiftUI

@main
struct MusicKeyBoardApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .defaultSize(width: 900, height: 650)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
