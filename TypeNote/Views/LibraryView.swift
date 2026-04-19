import SwiftUI
import UniformTypeIdentifiers

/// Main library window: category sidebar on the left, score sections on the right.
struct LibraryView: View {
    var onPlayTapped: () -> Void

    @Environment(AppState.self) private var appState
    @State private var showFileImporter = false
    @State private var importType: ScoreType = .musicXML
    @State private var showJianpuEditor = false
    @State private var editingItem: ScoreItem?
    @State private var selectedCategoryId: String?

    // MARK: - Grouping

    private static let myLibraryId = "my_library"

    private var groupedSections: [(id: String, name: String, iconName: String, items: [ScoreItem])] {
        var buckets: [String: [ScoreItem]] = [:]
        for item in appState.library.items {
            let key = BuiltInScores.categoryId(for: item.name) ?? Self.myLibraryId
            buckets[key, default: []].append(item)
        }

        var result: [(id: String, name: String, iconName: String, items: [ScoreItem])] = []

        for cat in BuiltInScores.scoreCategories {
            if let items = buckets[cat.id], !items.isEmpty {
                result.append((id: cat.id, name: cat.name, iconName: cat.iconName, items: items))
            }
        }

        if let myItems = buckets[Self.myLibraryId], !myItems.isEmpty {
            result.append((id: Self.myLibraryId, name: "My Library", iconName: "folder.badge.plus", items: myItems))
        }

        return result
    }

    var body: some View {
        HSplitView {
            categorySidebar
            scoreContent
        }
        .navigationTitle("Score Library")
        .toolbar {
            ToolbarItem(placement: .principal) {
                InputPlaceholderButton(action: onPlayTapped)
            }
            ToolbarItemGroup(placement: .automatic) {
                importMenu
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                appState.importFileWithBPM(url: url, type: importType)
            }
        }
        .sheet(isPresented: $showJianpuEditor) {
            LibraryJianpuEditor()
                .environment(appState)
        }
        .sheet(item: $editingItem) { item in
            ScoreEditor(item: item)
                .environment(appState)
        }
    }

    // MARK: - Category Sidebar

    private var categorySidebar: some View {
        List(selection: $selectedCategoryId) {
            ForEach(groupedSections, id: \.id) { section in
                Label(LocalizedStringKey(section.name), systemImage: section.iconName)
                    .font(.callout)
                    .tag(section.id)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 150, idealWidth: 170, maxWidth: 190)
    }

    // MARK: - Score Content

    @ViewBuilder
    private var scoreContent: some View {
        if appState.library.items.isEmpty {
            emptyState
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(groupedSections, id: \.id) { section in
                            sectionHeader(name: section.name, icon: section.iconName, count: section.items.count)
                                .id(section.id)

                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 140), spacing: 16)],
                                spacing: 16
                            ) {
                                ForEach(section.items) { item in
                                    ScoreCard(
                                        item: item,
                                        isActive: appState.activeScoreId == item.id
                                    ) {
                                        appState.loadFromLibrary(item)
                                    } onEdit: {
                                        editingItem = item
                                    } onDelete: {
                                        appState.library.remove(item)
                                    } onPreviewStart: {
                                        appState.previewScore(item)
                                    } onPreviewStop: {
                                        appState.stopScorePreview()
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: selectedCategoryId) { _, newId in
                    if let id = newId {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(id, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(name: String, icon: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(LocalizedStringKey(name))
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
        .padding(.top, 16)
        .padding(.bottom, 10)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Import Menu

    private var importMenu: some View {
        Menu {
            Button {
                showJianpuEditor = true
            } label: {
                Label("Numbered Notation", systemImage: "number")
            }
            Button {
                importType = .musicXML
                showFileImporter = true
            } label: {
                Label("MusicXML", systemImage: "doc.text")
            }
            Button {
                importType = .midi
                showFileImporter = true
            } label: {
                Label("MIDI", systemImage: "pianokeys")
            }
        } label: {
            Image(systemName: "plus")
        }
        .help("Import Score")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No Scores Yet")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Import Numbered Notation, MusicXML, or MIDI files")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var allowedTypes: [UTType] {
        switch importType {
        case .musicXML:
            return [.xml, UTType(filenameExtension: "musicxml") ?? .xml]
        case .midi:
            return [UTType(filenameExtension: "mid") ?? .data, UTType(filenameExtension: "midi") ?? .data]
        case .jianpu:
            return []
        }
    }
}

// MARK: - Score Row (List item with drag reorder)

struct ScoreRow: View {
    let item: ScoreItem
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Type tag
                Text(item.localizedTypeLabel)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(tagColor.cornerRadius(4))

                // Name
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.body.bold())
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if item.type == .jianpu, let text = item.jianpuText {
                        Text(text.prefix(40))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // BPM badge
                if let bpm = item.bpm {
                    Text("\(Int(bpm)) BPM")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1).cornerRadius(4))
                }

                // Active indicator
                if isActive {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { onEdit() } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var tagColor: Color {
        switch item.type {
        case .jianpu: return .orange
        case .musicXML: return .blue
        case .midi: return .purple
        }
    }
}

// MARK: - Score Card

struct ScoreCard: View {
    let item: ScoreItem
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onPreviewStart: () -> Void
    let onPreviewStop: () -> Void

    @State private var isHovering = false
    @State private var isPreviewing = false

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Icon area with type tag
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isActive ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.08))
                            .frame(height: 80)

                        ZStack {
                            // Score preview text / icon — dims while previewing
                            VStack(spacing: 4) {
                                Image(systemName: item.iconName)
                                    .font(.title2)
                                    .foregroundStyle(isActive ? Color.accentColor : Color.secondary)

                                if item.type == .jianpu, let text = item.jianpuText {
                                    Text(text.prefix(30))
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .padding(.horizontal, 8)
                                }
                            }
                            .opacity(isPreviewing ? 0.2 : 1)

                            // Music pulse bars — shown while previewing
                            if isPreviewing {
                                MusicPulseView()
                                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            }
                        }
                    }

                    // Type tag
                    Text(item.localizedTypeLabel)
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(tagColor.cornerRadius(3))
                        .padding(4)
                }

                // Name + BPM
                VStack(spacing: 2) {
                    Text(item.name)
                        .font(.caption.bold())
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if let bpm = item.bpm {
                        Text("\(Int(bpm)) BPM")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovering ? Color.gray.opacity(0.1) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isActive ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
            if hovering {
                onPreviewStart()
                withAnimation(.easeIn(duration: 0.2)) { isPreviewing = true }
            } else {
                onPreviewStop()
                withAnimation(.easeOut(duration: 0.15)) { isPreviewing = false }
            }
        }
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var tagColor: Color {
        switch item.type {
        case .jianpu: return .orange
        case .musicXML: return .blue
        case .midi: return .purple
        }
    }
}

// MARK: - Music Pulse Animation

/// Three animated bars that bounce at different phases, like a music equalizer.
private struct MusicPulseView: View {
    @State private var phase = false

    private let bars: [(upScale: CGFloat, delay: Double)] = [
        (0.55, 0.00),
        (1.00, 0.15),
        (0.70, 0.30),
        (0.85, 0.08),
        (0.45, 0.22),
    ]

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(bars.indices, id: \.self) { i in
                let bar = bars[i]
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor.opacity(0.85))
                    .frame(width: 4, height: phase ? 28 * bar.upScale : 8)
                    .animation(
                        .easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(bar.delay),
                        value: phase
                    )
            }
        }
        .onAppear { phase = true }
        .onDisappear { phase = false }
    }
}

// MARK: - Score Editor (edit existing scores)

struct ScoreEditor: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var bpm: Double
    @State private var jianpuText: String
    @State private var jianpuKeyIndex: Int
    @State private var isVisible = false

    private let item: ScoreItem

    init(item: ScoreItem) {
        self.item = item
        _name = State(initialValue: item.name)
        _bpm = State(initialValue: item.bpm ?? 120)
        _jianpuText = State(initialValue: item.jianpuText ?? "")
        _jianpuKeyIndex = State(initialValue: item.jianpuKeyIndex ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit Score")
                .font(.headline)

            TextField("Score Name", text: $name)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 12) {
                if item.type == .jianpu {
                    HStack(spacing: 4) {
                        Text("Key:")
                            .font(.caption)
                        Picker("", selection: $jianpuKeyIndex) {
                            ForEach(Array(JianpuParser.keys.enumerated()), id: \.offset) { index, key in
                                Text(key.name).tag(index)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 90)
                    }
                }

                HStack(spacing: 4) {
                    Text("BPM:")
                        .font(.caption)
                    TextField("BPM", value: $bpm, format: .number)
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                }
            }

            if item.type == .jianpu {
                TextEditor(text: $jianpuText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 80)
                    .border(Color.gray.opacity(0.3))

                Text("1-7=notes  0=rest  '=up  ,=down  _=half  -=extend  #/b=sharp/flat")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Button("Save") {
                    saveChanges()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 440, height: item.type == .jianpu ? 320 : 160)
        .opacity(isVisible ? 1 : 0)
        .task {
            await Task.yield()
            withAnimation(.easeIn(duration: 0.12)) { isVisible = true }
        }
    }

    private func saveChanges() {
        var updated = item
        updated.name = name.isEmpty ? item.name : name
        updated.bpm = bpm

        if item.type == .jianpu {
            updated.jianpuText = jianpuText
            updated.jianpuKeyIndex = jianpuKeyIndex
        }

        appState.library.update(updated)

        if appState.activeScoreId == item.id {
            appState.loadFromLibrary(updated)
        }
    }
}

// MARK: - Jianpu Editor (create new)

struct LibraryJianpuEditor: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var text = "1 1 5 5 6 6 5 - 4 4 3 3 2 2 1 -"
    @State private var keyIndex = 0
    @State private var tempo: Double = 120
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Numbered Score")
                .font(.headline)

            TextField("Score Name", text: $name)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("Key:")
                        .font(.caption)
                    Picker("", selection: $keyIndex) {
                        ForEach(Array(JianpuParser.keys.enumerated()), id: \.offset) { index, key in
                            Text(key.name).tag(index)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 90)
                }

                HStack(spacing: 4) {
                    Text("BPM:")
                        .font(.caption)
                    TextField("BPM", value: $tempo, format: .number)
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                }
            }

            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 80)
                .border(Color.gray.opacity(0.3))

            VStack(alignment: .leading, spacing: 2) {
                Text("Format: [#/b]note['][_]   e.g. 1'_ = half-beat high do")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("1-7=note  0=rest  '=octave up  ,=octave down  _=half duration  -=extend  #/b=sharp/flat")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Button("Save & Load") {
                    let scoreName = name.isEmpty ? "Numbered \(Date().formatted(.dateTime.month().day().hour().minute()))" : name
                    appState.library.saveJianpu(name: scoreName, text: text, keyIndex: keyIndex, bpm: tempo)
                    if let item = appState.library.items.first(where: { $0.name == scoreName }) {
                        appState.loadFromLibrary(item)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 440, height: 320)
        .opacity(isVisible ? 1 : 0)
        .task {
            await Task.yield()
            withAnimation(.easeIn(duration: 0.12)) { isVisible = true }
        }
    }
}
