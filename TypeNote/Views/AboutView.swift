import SwiftUI
import AppKit

/// About window showing app info, version, and open-source credits.
struct AboutView: View {
    @EnvironmentObject private var updateController: UpdateController

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 0) {
            // App icon + name
            VStack(spacing: 12) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .padding(.top, 32)

                Text("TypeNote")
                    .font(.largeTitle.bold())

                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Check for Updates...") {
                    updateController.checkForUpdates()
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .disabled(!updateController.canCheckForUpdates)
                .padding(.top, 2)
            }

            Divider()
                .padding(.vertical, 20)

            // Description
            Text("Turn your keyboard into a musical instrument.\nType to play notes, follow scores, and practice anywhere.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Divider()
                .padding(.vertical, 20)

            // Credits section
            VStack(alignment: .leading, spacing: 10) {
                Text("Credits")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                creditRow(
                    title: "GeneralUser GS SoundFont",
                    detail: "by S. Christian Collins",
                    url: "https://schristiancollins.com/generaluser.php"
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            // Copyright
            Text("© 2025 TypeNote. Built with ♥")
                .font(.caption2)
                .foregroundStyle(.quaternary)
                .padding(.bottom, 24)
        }
        .frame(width: 360, height: 420)
    }

    // MARK: - Credit Row

    private func creditRow(title: String, detail: String, url: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "music.note")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                Link(detail, destination: URL(string: url)!)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }
}

#Preview {
    AboutView()
}
