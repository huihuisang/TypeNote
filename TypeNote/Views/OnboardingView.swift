import SwiftUI

// MARK: - Onboarding Page Index

private enum OnboardingPage: Int, CaseIterable {
    case welcome = 0
    case soundWave
    case timbres
    case melody
    case menuBar
    case permissions
}

// MARK: - OnboardingView

/// Paged onboarding: 4 illustrated intro pages → permission setup.
struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    var onComplete: () -> Void

    @State private var currentPage: OnboardingPage = .welcome

    private var isPermissionPage: Bool {
        currentPage == .permissions
    }

    var body: some View {
        VStack(spacing: 0) {
            // Page content
            ZStack {
                ForEach(OnboardingPage.allCases, id: \.rawValue) { page in
                    if page == currentPage {
                        pageContent(for: page)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Page indicator + button
            if !isPermissionPage {
                VStack(spacing: 20) {
                    // Dot indicator
                    HStack(spacing: 8) {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(index == currentPage.rawValue
                                      ? Color.primary
                                      : Color.primary.opacity(0.2))
                                .frame(width: 6, height: 6)
                        }
                    }

                    Button {
                        advance()
                    } label: {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 32)
            }
        }
        .frame(width: 480, height: 520)
    }

    // MARK: - Page Router

    @ViewBuilder
    private func pageContent(for page: OnboardingPage) -> some View {
        switch page {
        case .welcome:
            WelcomePage()

        case .soundWave:
            IllustrationPage(
                title: "Ambient Typing",
                caption: "Type anywhere. Relax and listen\nto the sound of every keystroke."
            ) { SoundWaveAnimation() }

        case .timbres:
            IllustrationPage(
                title: "Pick Your Sound",
                caption: "128 timbres to match your mood.\nSwitch in two clicks."
            ) { TimbresAnimation() }

        case .melody:
            IllustrationPage(
                title: "Follow a Melody",
                caption: "Paste a melody.\nYour keystrokes will follow the notes."
            ) { MelodyAnimation() }

        case .menuBar:
            IllustrationPage(
                title: "Always There",
                caption: "Works in any app, any text field.\nQuietly lives in your menu bar."
            ) { MenuBarAnimation() }

        case .permissions:
            PermissionsStep(onComplete: onComplete)
        }
    }

    private func advance() {
        let next = OnboardingPage(rawValue: currentPage.rawValue + 1) ?? .permissions
        withAnimation(.easeInOut(duration: 0.35)) {
            currentPage = next
        }
    }
}

// MARK: - Welcome Page

/// Logo, app name, and slogan appear in sequence.
private struct WelcomePage: View {
    @State private var showLogo = false
    @State private var showName = false
    @State private var showSlogan = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 80, height: 80)
                .opacity(showLogo ? 1 : 0)
                .scaleEffect(showLogo ? 1 : 0.8)

            Spacer().frame(height: 20)

            Text("TypeNote")
                .font(.largeTitle.bold())
                .opacity(showName ? 1 : 0)
                .offset(y: showName ? 0 : 10)

            Spacer().frame(height: 12)

            Text("Your keyboard still types.\nIt just sounds different now.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(showSlogan ? 1 : 0)
                .offset(y: showSlogan ? 0 : 8)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) { showLogo = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) { showName = true }
            withAnimation(.easeOut(duration: 0.5).delay(1.0)) { showSlogan = true }
        }
    }
}

// MARK: - Illustration Page Template

private struct IllustrationPage<Illustration: View>: View {
    let title: LocalizedStringKey
    let caption: LocalizedStringKey
    @ViewBuilder let illustration: () -> Illustration

    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            illustration()
                .frame(width: 200, height: 200)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.92)

            Spacer().frame(height: 32)

            Text(title)
                .font(.title2.bold())
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 8)

            Spacer().frame(height: 8)

            Text(caption)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 6)

            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                showContent = true
            }
        }
    }
}

// MARK: - Animation 1: Menu Bar

/// A simplified MacBook with a menu bar icon appearing.
private struct MenuBarAnimation: View {
    @State private var drawn: CGFloat = 0
    @State private var barOpacity: Double = 0
    @State private var iconOpacity: Double = 0
    @State private var iconBounce: CGFloat = 6

    fileprivate static let screenTop: CGFloat = -50
    fileprivate static let screenW: CGFloat = 160
    fileprivate static let barH: CGFloat = 12

    var body: some View {
        ZStack {
            MacBookShape()
                .trim(from: 0, to: drawn)
                .stroke(Color.primary.opacity(0.5), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))

            // Menu bar background + separator
            let barY = Self.screenTop + Self.barH / 2 + 1
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(width: Self.screenW - 2, height: Self.barH)
                .offset(y: barY)
                .opacity(barOpacity)

            Rectangle()
                .fill(Color.primary.opacity(0.15))
                .frame(width: Self.screenW - 2, height: 0.5)
                .offset(y: Self.screenTop + Self.barH + 1)
                .opacity(barOpacity)

            // Music note icon (right side of menu bar)
            Image(systemName: "music.note")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.primary)
                .offset(x: Self.screenW / 2 - 16, y: barY + iconBounce)
                .opacity(iconOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) { drawn = 1 }
            withAnimation(.easeIn(duration: 0.3).delay(0.8)) { barOpacity = 1 }
            withAnimation(.easeOut(duration: 0.5).delay(1.2)) { iconOpacity = 1 }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(1.2)) { iconBounce = 0 }
        }
    }
}

/// Simplified MacBook: screen + hinge + base deck.
private struct MacBookShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let screenTop = rect.midY + MenuBarAnimation.screenTop
        let w = MenuBarAnimation.screenW
        let screenH: CGFloat = 100
        let r: CGFloat = 6

        var p = Path()

        // Screen
        p.addRoundedRect(
            in: CGRect(x: cx - w / 2, y: screenTop, width: w, height: screenH),
            cornerSize: CGSize(width: r, height: r)
        )

        // Camera dot (inside screen, top center)
        p.addEllipse(in: CGRect(x: cx - 2, y: screenTop + 4, width: 4, height: 4))

        // Base deck (keyboard body)
        let baseTop = screenTop + screenH + 3
        let baseH: CGFloat = 10
        let baseW = w + 16
        let baseR: CGFloat = 3
        p.addRoundedRect(
            in: CGRect(x: cx - baseW / 2, y: baseTop, width: baseW, height: baseH),
            cornerSize: CGSize(width: baseR, height: baseR)
        )

        return p
    }
}

// MARK: - Animation 2: Sound Wave

/// Full QWERTY keyboard with one key bouncing and a note floating up.
private struct SoundWaveAnimation: View {
    private static let rows: [[String]] = [
        ["Q","W","E","R","T","Y","U","I","O","P"],
        ["A","S","D","F","G","H","J","K","L"],
        ["Z","X","C","V","B","N","M"],
    ]
    private static let keySize: CGFloat = 20
    private static let keySpacing: CGFloat = 3
    private static let rowSpacing: CGFloat = 3

    @State private var activeKey = ""
    @State private var pressed = false
    @State private var noteY: CGFloat = 20
    @State private var noteOpacity: Double = 0
    @State private var noteX: CGFloat = 0

    private let allKeys = rows.flatMap { $0 }

    var body: some View {
        ZStack {
            // Floating note
            Image(systemName: "music.note")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary.opacity(noteOpacity))
                .offset(x: noteX, y: noteY)

            // Keyboard (each row centered naturally)
            VStack(spacing: Self.rowSpacing) {
                ForEach(0..<Self.rows.count, id: \.self) { r in
                    HStack(spacing: Self.keySpacing) {
                        ForEach(Self.rows[r], id: \.self) { key in
                            KeyCap(letter: key, size: Self.keySize)
                                .offset(y: (key == activeKey && pressed) ? 2 : 0)
                        }
                    }
                }
            }
            .offset(y: 20)
        }
        .onAppear {
            pickAndPlay(delay: 0.4)
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                reset()
                pickAndPlay(delay: 0.05)
            }
        }
    }

    private func pickAndPlay(delay d: Double) {
        // Pick a random key different from last
        var next = allKeys.randomElement() ?? "F"
        while next == activeKey { next = allKeys.randomElement() ?? "F" }
        activeKey = next
        noteX = xOffset(for: next)

        // Key press
        withAnimation(.easeIn(duration: 0.1).delay(d)) { pressed = true }
        withAnimation(.easeOut(duration: 0.15).delay(d + 0.15)) { pressed = false }

        // Note float up
        withAnimation(.easeOut(duration: 0.1).delay(d + 0.1)) {
            noteOpacity = 0.7
            noteY = 5
        }
        withAnimation(.easeOut(duration: 1.2).delay(d + 0.2)) { noteY = -55 }
        withAnimation(.easeIn(duration: 0.5).delay(d + 0.9)) { noteOpacity = 0 }
    }

    private func reset() {
        pressed = false
        noteY = 20
        noteOpacity = 0
    }

    /// Approximate horizontal offset for a key relative to keyboard center.
    private func xOffset(for key: String) -> CGFloat {
        let step = Self.keySize + Self.keySpacing
        for row in Self.rows {
            guard let idx = row.firstIndex(of: key) else { continue }
            let count = CGFloat(row.count)
            let rowWidth = count * Self.keySize + (count - 1) * Self.keySpacing
            return CGFloat(idx) * step + Self.keySize / 2 - rowWidth / 2
        }
        return 0
    }
}

/// A single key cap with a letter label.
private struct KeyCap: View {
    let letter: String
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.primary.opacity(0.5), lineWidth: 1)
                .frame(width: size, height: size)

            Text(letter)
                .font(.system(size: size * 0.5, weight: .medium, design: .rounded))
                .foregroundStyle(.primary.opacity(0.7))
        }
    }
}

// MARK: - Animation 3: Timbres

/// Instrument icons in a 4×2 grid, lighting up one by one.
private struct TimbresAnimation: View {
    @State private var activeIndex = -1

    // All 16 GM categories — icons match InstrumentLibrary
    private let instruments = [
        "pianokeys", "bell", "music.quarternote.3", "guitars",
        "wave.3.right", "music.note", "person.3", "horn",
        "wind", "lines.measurement.horizontal", "waveform", "waveform.path",
        "sparkles", "globe", "metronome", "speaker.wave.2",
    ]
    private let grid = [GridItem](repeating: GridItem(.fixed(28), spacing: 16), count: 4)

    var body: some View {
        LazyVGrid(columns: grid, spacing: 12) {
            ForEach(0..<instruments.count, id: \.self) { i in
                Image(systemName: instruments[i])
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(i == activeIndex ? Color.primary : Color.primary.opacity(0.2))
                    .scaleEffect(i == activeIndex ? 1.25 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: activeIndex)
                    .frame(width: 28, height: 28)
            }
        }
        .onAppear {
            var index = 0
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                withAnimation {
                    activeIndex = index % instruments.count
                }
                index += 1
            }
        }
    }
}

// MARK: - Animation 4: Melody

/// A row of notes that light up one by one, simulating keystroke → note.
/// Notes on a staff that light up sequentially.
private struct MelodyAnimation: View {
    @State private var activeNote = -1
    @State private var visible = false

    // Twinkle Twinkle: C C G G A A G — mapped to staff line positions
    // Staff line spacing = 14pt; positions relative to middle line (B4=line 3)
    // C5=0 sits on line below middle, G5=-2 lines up, A5=-3 lines up
    private static let lineSpacing: CGFloat = 14
    private let notes: [CGFloat] = [
         2,  2,  // C (below middle line)
        -1, -1,  // G (above middle line)
        -2, -2,  // A (higher)
        -1,      // G
    ].map { $0 * lineSpacing }

    var body: some View {
        ZStack {
            // Staff lines (5 lines, wider spacing)
            VStack(spacing: Self.lineSpacing) {
                ForEach(0..<5, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(height: 0.5)
                }
            }
            .frame(width: 190)

            // Music note symbols
            HStack(spacing: 16) {
                ForEach(0..<notes.count, id: \.self) { i in
                    Image(systemName: "music.note")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                        .opacity(noteOpacity(for: i))
                        .offset(y: notes[i])
                        .animation(.easeInOut(duration: 0.25), value: activeNote)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { visible = true }

            var index = 0
            Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.25)) {
                    activeNote = index
                }
                index += 1
                if index >= notes.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation { activeNote = -1 }
                    }
                    index = 0
                }
            }
        }
    }

    private func noteOpacity(for index: Int) -> Double {
        guard visible else { return 0 }
        if activeNote < 0 { return 0.15 }
        return index <= activeNote ? 0.9 : 0.15
    }
}

// MARK: - Permissions Step

private struct PermissionsStep: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    var onComplete: () -> Void

    @State private var hasInputMonitoring = PermissionManager.hasInputMonitoring
    @State private var pollingTask: Task<Void, Never>?
    @State private var didRestartMonitor = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon + message
            VStack(spacing: 16) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)

                Text("One more thing.")
                    .font(.title3.weight(.medium))

                Text("TypeNote needs to listen to your keystrokes\nto play sounds. Nothing is recorded or sent anywhere.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer().frame(height: 40)

            PermissionCard(
                icon: "keyboard",
                title: "Input Monitoring",
                description: "Detect keystrokes to trigger sounds.",
                isGranted: hasInputMonitoring,
                isRequired: true
            ) {
                PermissionManager.ensureInputMonitoring()
            }
            .padding(.horizontal, 40)

            Spacer()

            // Get started button
            Button {
                PermissionManager.completeOnboarding()
                NSApp.setActivationPolicy(.regular)
                openWindow(id: "library")
                NSApp.activate(ignoringOtherApps: true)
                onComplete()
            } label: {
                Text(hasInputMonitoring ? "Get Started" : "Skip for Now")
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(hasInputMonitoring ? .accentColor : .gray)
            .padding(.horizontal, 40)

            Spacer().frame(height: 32)
        }
        .onAppear { startPolling() }
        .onDisappear { pollingTask?.cancel() }
    }

    /// Poll permission status since system grants happen out of process.
    private func startPolling() {
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                hasInputMonitoring = PermissionManager.hasInputMonitoring
                if hasInputMonitoring, !didRestartMonitor {
                    didRestartMonitor = true
                    appState.restartMonitorIfNeeded()
                }
            }
        }
    }
}

// MARK: - Permission Card

struct PermissionCard: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let isGranted: Bool
    let isRequired: Bool
    let onRequest: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Status icon
            ZStack {
                Circle()
                    .fill(isGranted ? Color.green.opacity(0.12) : Color.gray.opacity(0.08))
                    .frame(width: 44, height: 44)

                Image(systemName: isGranted ? "checkmark" : icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isGranted ? .green : .secondary)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Action button
            if !isGranted {
                Button("Grant") {
                    onRequest()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.06))
        )
        .animation(.easeInOut(duration: 0.3), value: isGranted)
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .environment(AppState())
}
