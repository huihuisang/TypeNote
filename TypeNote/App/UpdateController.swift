import Combine
import Foundation
import Sparkle

// MARK: - UpdateController

/// Manages the Sparkle auto-updater lifecycle and exposes update state to SwiftUI views.
final class UpdateController: ObservableObject {

    @Published var canCheckForUpdates = false

    /// The underlying Sparkle controller. Keep alive for the full app lifetime.
    let updaterController: SPUStandardUpdaterController

    private let feedDelegate = UpdaterFeedDelegate()
    private var cancellable: AnyCancellable?

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: feedDelegate,
            userDriverDelegate: nil
        )

        // Mirror Sparkle's internal canCheckForUpdates into our @Published property.
        cancellable = updaterController.updater
            .publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .assign(to: \.canCheckForUpdates, on: self)
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}

// MARK: - UpdaterFeedDelegate

/// Provides the appcast feed URL to Sparkle via the delegate protocol,
/// avoiding the need to embed SUFeedURL in an Info.plist file.
private final class UpdaterFeedDelegate: NSObject, SPUUpdaterDelegate {

    private static let appcastURL =
        "https://raw.githubusercontent.com/huihuisang/TypeNote/main/appcast.xml"

    func feedURLString(for updater: SPUUpdater) -> String? {
        return Self.appcastURL
    }
}
