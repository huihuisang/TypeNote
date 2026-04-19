import SwiftUI

/// Identifiable bubble model for the particle system.
/// All animation parameters are passed explicitly at spawn time so that
/// re-renders never mutate existing bubbles' trajectories.
struct BubbleParticle: Identifiable {
    let id = UUID()
    let symbol: String
    let startX: CGFloat
    let duration: Double
    let riseHeight: CGFloat
    let wobbleAmplitude: CGFloat
    let wobbleFrequency: Double
    let wobblePhase: Double
    let maxScale: CGFloat
}

/// Full-screen overlay with glowing text field and floating note bubbles.
/// Appears when user clicks the toolbar play field.
struct PlayOverlayView: View {
    @Binding var isPresented: Bool
    @Environment(AppState.self) private var appState

    @State private var inputText = ""
    @FocusState private var isFocused: Bool
    @State private var bubbles: [BubbleParticle] = []

    // Captured from GeometryReader so spawnBubble() knows the container width
    @State private var containerWidth: CGFloat = 0

    // Controls the open animation (bottom-up slide + fade).
    // Starts false so the entire ZStack is invisible on the first render frame.
    @State private var contentVisible = false

    // Mirrors whether inputText is non-empty; also flips on first IME pre-edit keydown
    @State private var hasInput = false

    // NSEvent monitor reference — must be removed on disappear
    @State private var keyMonitor: Any?

    private let fieldWidth: CGFloat = 520

    var body: some View {
        ZStack {
            // Blurred background
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                Spacer()

                // Guide text — drifts upward and fades out after first keystroke
                if !hasInput {
                    guideView
                        .padding(.bottom, 40)
                        .transition(.slideUpFade)
                }

                GlowingTextField(
                    text: $inputText,
                    isFocused: $isFocused
                ) {
                    // Glow pulse only — bubble spawning is tied to actual note playback
                }
                .background {
                    GeometryReader { geo in
                        ZStack {
                            ForEach(bubbles) { bubble in
                                NoteBubbleView(
                                    symbol: bubble.symbol,
                                    duration: bubble.duration,
                                    riseHeight: bubble.riseHeight,
                                    wobbleAmplitude: bubble.wobbleAmplitude,
                                    wobbleFrequency: bubble.wobbleFrequency,
                                    wobblePhase: bubble.wobblePhase,
                                    maxScale: bubble.maxScale
                                ) {
                                    bubbles.removeAll { $0.id == bubble.id }
                                }
                                .position(x: bubble.startX, y: 0)
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .onAppear {
                            containerWidth = geo.size.width
                        }
                    }
                }
                // Sync hasInput with actual text content so clearing the field restores the guide
                .onChange(of: inputText) {
                    let shouldShow = !inputText.isEmpty
                    guard shouldShow != hasInput else { return }
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                        hasInput = shouldShow
                    }
                }
                // Spawn a bubble only when a real note is played
                .onChange(of: appState.notePlayedCount) {
                    spawnBubble()
                }

                Text("Press Esc to close")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 16)
                    .padding(.bottom, 52)
            }
        }
        // Apply reveal animation to the whole ZStack (background + content together),
        // preventing any sub-view from flashing on the first render frame.
        .opacity(contentVisible ? 1 : 0)
        .offset(y: contentVisible ? 0 : 50)
        .task {
            // Yield so SwiftUI completes the first render (opacity 0) before animating in.
            await Task.yield()
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                contentVisible = true
            }
        }
        .onAppear {
            // Small delay ensures the field is in the window's responder chain
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isFocused = true
            }
            // Monitor key events before IME processes them,
            // so pinyin/other IME composition also dismisses the guide text.
            // Deletion keys are excluded so backspace on empty text doesn't suppress the guide.
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                let isDeletion = event.keyCode == 51 || event.keyCode == 117 // backspace, forward-delete
                if !hasInput && !isDeletion {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                        hasInput = true
                    }
                }
                return event
            }
            // Screenshot mode: pre-spawn bubbles and hide the guide text
            if TypeNoteApp.isScreenshotMode {
                hasInput = true
                inputText = "1 1 5 5 6 6 5 -"
                containerWidth = fieldWidth
                for i in 0..<18 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                        spawnBubble()
                    }
                }
            }
        }
        .onDisappear {
            if let monitor = keyMonitor {
                NSEvent.removeMonitor(monitor)
                keyMonitor = nil
            }
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
        .transition(.opacity)
    }

    // MARK: - Guide View

    private var guideView: some View {
        VStack(spacing: 10) {
            Image(systemName: "pianokeys.inverse")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            Text("Start typing to play music")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Every keystroke is a note — just start typing")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Actions

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            isPresented = false
        }
    }

    private func spawnBubble() {
        let width = containerWidth > 0 ? containerWidth : 600
        let centerX = width / 2
        let halfField = fieldWidth / 2

        let wobbleAmplitude = CGFloat.random(in: 25...55)
        let safeHalf = halfField - wobbleAmplitude

        let particle = BubbleParticle(
            symbol: NoteBubbleView.randomSymbol(),
            startX: CGFloat.random(in: (centerX - safeHalf)...(centerX + safeHalf)),
            duration: Double.random(in: 2.5...4.0),
            riseHeight: CGFloat.random(in: 260...380),
            wobbleAmplitude: wobbleAmplitude,
            wobbleFrequency: Double.random(in: 1.2...2.2),
            wobblePhase: Double.random(in: 0...(.pi * 2)),
            maxScale: CGFloat.random(in: 1.1...1.6)
        )
        bubbles.append(particle)

        if bubbles.count > 30 {
            bubbles.removeFirst()
        }
    }
}

// MARK: - Custom transition helpers

private struct OffsetOpacityModifier: ViewModifier {
    let offsetY: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .offset(y: offsetY)
            .opacity(opacity)
    }
}

private extension AnyTransition {
    /// Inserts from slightly below; removes by drifting upward — both with fade.
    static var slideUpFade: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: OffsetOpacityModifier(offsetY: 24, opacity: 0),
                identity: OffsetOpacityModifier(offsetY: 0, opacity: 1)
            ),
            removal: .modifier(
                active: OffsetOpacityModifier(offsetY: -24, opacity: 0),
                identity: OffsetOpacityModifier(offsetY: 0, opacity: 1)
            )
        )
    }
}
