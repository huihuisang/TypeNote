import SwiftUI

/// A single floating bubble containing a music note symbol.
/// Rises from its anchor point with a sinusoidal left-right sway,
/// growing in size and fading out near the top.
///
/// Animation parameters are passed in from BubbleParticle (computed once
/// at spawn time) so that adding new bubbles never mutates existing ones.
struct NoteBubbleView: View {
    let symbol: String
    let duration: Double
    let riseHeight: CGFloat
    let wobbleAmplitude: CGFloat
    let wobbleFrequency: Double
    let wobblePhase: Double
    let maxScale: CGFloat
    let onComplete: () -> Void

    // Record when the bubble became visible
    @State private var startDate: Date? = nil

    private let bubbleSize: CGFloat = 36

    var body: some View {
        TimelineView(.animation) { timeline in
            // Elapsed seconds since bubble appeared
            let elapsed = startDate.map { timeline.date.timeIntervalSince($0) } ?? 0
            let progress = min(elapsed / duration, 1.0)

            // Ease-out curve: fast rise at start, slows near top
            let easedProgress = 1 - pow(1 - progress, 2)
            let yOffset = -easedProgress * riseHeight

            // Sinusoidal left-right sway
            let xOffset = sin(elapsed * wobbleFrequency + wobblePhase) * wobbleAmplitude

            // Scale up as bubble rises
            let scale = 0.35 + easedProgress * (maxScale - 0.35)

            // Fade out during the last 25% of lifetime
            let opacity: Double = progress > 0.75
                ? Double(1.0 - (progress - 0.75) / 0.25)
                : 1.0

            bubbleBody
                .scaleEffect(scale)
                .offset(x: xOffset, y: yOffset)
                .opacity(opacity)
        }
        .onAppear {
            startDate = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                onComplete()
            }
        }
    }

    // MARK: - Bubble Appearance

    private var bubbleBody: some View {
        ZStack {
            // Soap bubble base with radial gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.25),
                            .blue.opacity(0.08),
                            .purple.opacity(0.05),
                            .clear
                        ],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: bubbleSize / 2
                    )
                )
                .frame(width: bubbleSize, height: bubbleSize)
                .overlay(
                    // Highlight arc for 3D glass look
                    Circle()
                        .trim(from: 0.05, to: 0.35)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: bubbleSize * 0.75, height: bubbleSize * 0.75)
                        .rotationEffect(.degrees(-30))
                )
                .overlay(
                    // Subtle rainbow sheen
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [
                                    .pink.opacity(0.1),
                                    .blue.opacity(0.1),
                                    .green.opacity(0.1),
                                    .yellow.opacity(0.1),
                                    .pink.opacity(0.1)
                                ],
                                center: .center
                            )
                        )
                        .frame(width: bubbleSize, height: bubbleSize)
                        .blendMode(.overlay)
                )
                .shadow(color: .white.opacity(0.15), radius: 3, x: -1, y: -1)

            // Note symbol inside bubble
            Text(symbol)
                .font(.system(size: 14))
                .foregroundStyle(.primary.opacity(0.7))
        }
    }

    // MARK: - Static Helpers

    static let symbols = ["♪", "♫", "♬"]

    static func randomSymbol() -> String {
        symbols.randomElement() ?? "♪"
    }
}
