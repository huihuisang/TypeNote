import SwiftUI

/// Sidebar navigation item
enum LibrarySidebarItem: String, CaseIterable, Identifiable, Hashable {
    case scores = "Score Library"
    case instruments = "Instruments"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .scores: return "music.note.list"
        case .instruments: return "pianokeys"
        }
    }

    /// Localized display title for the sidebar item.
    var title: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

/// Main library window with sidebar navigation (Score Library + Instruments).
struct MainLibraryView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedItem: LibrarySidebarItem? = .scores
    @State private var showPlayOverlay = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack(spacing: 0) {
                List(selection: $selectedItem) {
                    ForEach(LibrarySidebarItem.allCases) { item in
                        Label(item.title, systemImage: item.iconName)
                            .tag(item)
                    }
                }
                .listStyle(.sidebar)

                // Now Playing card
                if appState.activeScoreId != nil {
                    NowPlayingCard()
                        .environment(appState)
                }
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
        } detail: {
            switch selectedItem {
            case .scores:
                LibraryView(onPlayTapped: { showPlayOverlay = true })
                    .environment(appState)
            case .instruments:
                InstrumentLibraryView(onPlayTapped: { showPlayOverlay = true })
                    .environment(appState)
            case nil:
                LibraryView(onPlayTapped: { showPlayOverlay = true })
                    .environment(appState)
            }
        }
        .frame(minWidth: 680, minHeight: 460)
        .overlay {
            if showPlayOverlay {
                PlayOverlayView(isPresented: $showPlayOverlay)
                        .environment(appState)
            }
        }
        .onChange(of: showPlayOverlay) {
            withAnimation(.easeInOut(duration: 0.25)) {
                columnVisibility = showPlayOverlay ? .detailOnly : .all
            }
        }
        .onChange(of: columnVisibility) {
            // Clicking the sidebar toggle while in play mode should dismiss the overlay
            if columnVisibility != .detailOnly && showPlayOverlay {
                withAnimation(.easeOut(duration: 0.25)) {
                    showPlayOverlay = false
                }
            }
        }
        .onDisappear {
            // Hide Dock icon when Library window closes
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

// MARK: - Shared toolbar input placeholder button

/// Shown as the .principal toolbar item in each detail view.
struct InputPlaceholderButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            withAnimation(.easeOut(duration: 0.25)) {
                action()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "pianokeys")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("Try a new sound for your keyboard")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .frame(alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .frame(maxWidth: 360)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Now Playing Card

struct NowPlayingCard: View {
    @Environment(AppState.self) private var appState

    private var instrumentName: String {
        appState.selectedInstrumentName
    }

    private var categoryName: String {
        switch appState.activeInstrument {
        case .gm(let program): return KeyMapping.categoryName(for: program)
        case .sf2:             return "Custom SoundFont"
        }
    }

    private var categoryIcon: String {
        switch appState.activeInstrument {
        case .gm(let program): return KeyMapping.categoryIcon(for: program)
        case .sf2:             return "waveform"
        }
    }

    private var progress: Double {
        guard !appState.score.isEmpty else { return 0 }
        return Double(appState.currentNoteIndex) / Double(appState.score.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Instrument info
            HStack(spacing: 4) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                (Text(LocalizedStringKey(categoryName)) + Text(verbatim: " · ") + Text(LocalizedStringKey(instrumentName)))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            // Score name
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text(appState.scoreName)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 3)
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * progress, height: 3)
                        .animation(.easeInOut(duration: 0.15), value: progress)
                }
            }
            .frame(height: 3)

            // Note count
            Text("\(appState.currentNoteIndex) / \(appState.score.count)")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
        )
        .padding(8)
    }
}
