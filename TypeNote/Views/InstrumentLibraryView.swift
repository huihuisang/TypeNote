import SwiftUI
import UniformTypeIdentifiers

// MARK: - Sidebar Item

/// Discriminated union for sidebar selection — a GM category or an imported SoundFont.
private enum SidebarItem: Hashable {
    case gmCategory(String)   // KeyMapping.Category.id
    case soundFont(UUID)      // SoundFont.id
}

/// Instrument browser: category sidebar on the left, scrollable full list on the right.
/// Clicking a category scrolls the right panel to that section instead of filtering.
struct InstrumentLibraryView: View {
    var onPlayTapped: () -> Void

    @Environment(AppState.self) private var appState
    @State private var selectedItem: SidebarItem? = .gmCategory(KeyMapping.categories.first?.id ?? "")
    @State private var showSF2Importer = false
    @State private var importErrorMessage: String?
    @State private var showImportError = false

    var body: some View {
        HSplitView {
            categorySidebar
            instrumentScrollList
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                InputPlaceholderButton(action: onPlayTapped)
            }
            ToolbarItem(placement: .primaryAction) {
                Button { showSF2Importer = true } label: {
                    Label("Import SoundFont", systemImage: "square.and.arrow.down")
                }
                .help("Import SF2 SoundFont")
            }
        }
        .fileImporter(
            isPresented: $showSF2Importer,
            allowedContentTypes: [UTType(filenameExtension: "sf2") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            handleSF2Import(result: result)
        }
        .alert("Import Failed", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage ?? "The SoundFont file could not be read.")
        }
    }

    // MARK: - Category Sidebar

    private var categorySidebar: some View {
        List(selection: $selectedItem) {
            // Built-in GM categories
            Section("General MIDI") {
                ForEach(KeyMapping.categories) { category in
                    Label(LocalizedStringKey(category.name), systemImage: category.iconName)
                        .font(.callout)
                        .tag(SidebarItem.gmCategory(category.id))
                }
            }

            // Imported SF2 SoundFonts
            if !appState.soundFontLibrary.soundFonts.isEmpty {
                Section("Custom SoundFonts") {
                    ForEach(appState.soundFontLibrary.soundFonts) { font in
                        Label(font.displayName, systemImage: "waveform")
                            .font(.callout)
                            .tag(SidebarItem.soundFont(font.id))
                            .contextMenu {
                                Button(role: .destructive) {
                                    removeSoundFont(font)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 160, idealWidth: 180, maxWidth: 200)
    }

    // MARK: - Instrument Full List with Anchor Scroll

    private var instrumentScrollList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // GM instrument sections
                    ForEach(KeyMapping.categories) { category in
                        sectionHeader(
                            icon: category.iconName,
                            title: LocalizedStringKey(category.name),
                            count: category.instruments.count
                        )
                        .id(SidebarItem.gmCategory(category.id))

                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 180, maximum: 260))],
                            spacing: 8
                        ) {
                            ForEach(category.instruments) { instrument in
                                let ref = InstrumentRef.gm(program: instrument.program)
                                InstrumentCard(
                                    name: LocalizedStringKey(instrument.name),
                                    subtitle: "GM \(instrument.program + 1)",
                                    isActive: appState.activeInstrument == ref,
                                    isLoaded: appState.isInstrumentLoaded(instrument.program)
                                ) {
                                    appState.selectInstrument(ref)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }

                    // Custom SF2 SoundFont sections (one per imported file)
                    ForEach(appState.soundFontLibrary.soundFonts) { font in
                        sectionHeader(
                            icon: "waveform",
                            title: LocalizedStringKey(font.displayName),
                            count: font.presets.count
                        )
                        .id(SidebarItem.soundFont(font.id))

                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 180, maximum: 260))],
                            spacing: 8
                        ) {
                            ForEach(font.presets) { preset in
                                let ref = InstrumentRef.sf2(sf2ID: font.id, preset: preset)
                                InstrumentCard(
                                    name: LocalizedStringKey(preset.name),
                                    subtitle: preset.subtitle,
                                    isActive: appState.activeInstrument == ref,
                                    isLoaded: false
                                ) {
                                    appState.selectInstrument(ref)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: selectedItem) { _, newItem in
                if let item = newItem {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(item, anchor: .top)
                    }
                }
            }
        }
    }

    private func sectionHeader(icon: String, title: LocalizedStringKey, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            Text("\(count)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.12).cornerRadius(4))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Actions

    private func handleSF2Import(result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importErrorMessage = error.localizedDescription
            showImportError = true
        case .success(let urls):
            guard let url = urls.first else { return }
            if let font = appState.soundFontLibrary.import(url: url) {
                selectedItem = .soundFont(font.id)
            } else {
                importErrorMessage = "No presets found in the selected file. Make sure it is a valid SF2 SoundFont."
                showImportError = true
            }
        }
    }

    private func removeSoundFont(_ font: SoundFont) {
        // Fall back to the first GM category if this font is selected
        if selectedItem == .soundFont(font.id) {
            selectedItem = .gmCategory(KeyMapping.categories.first?.id ?? "")
        }
        // Switch back to default GM instrument if the removed font's preset is active
        if case .sf2(let sf2ID, _) = appState.activeInstrument, sf2ID == font.id {
            appState.selectInstrument(program: 9, preview: false)
        }
        appState.soundFontLibrary.remove(font)
    }
}

// MARK: - Instrument Card

private struct InstrumentCard: View {
    let name: LocalizedStringKey
    let subtitle: String
    let isActive: Bool
    let isLoaded: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                // Active indicator dot
                Circle()
                    .fill(isActive ? Color.accentColor : Color.clear)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle().stroke(
                            isActive ? Color.clear : Color.secondary.opacity(0.3),
                            lineWidth: 1
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.callout)
                        .foregroundStyle(isActive ? Color.accentColor : .primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer(minLength: 0)

                // Status badge
                if isActive {
                    Text("ACTIVE")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.cornerRadius(4))
                } else if isLoaded {
                    Text("LOADED")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.15).cornerRadius(4))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive
                          ? Color.accentColor.opacity(0.08)
                          : Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
