import SwiftUI

/// A large text field with a soft breathing glow effect.
/// Idle: subtle white/silver pulse. On keystroke: bright burst.
struct GlowingTextField: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    var onKeyPress: () -> Void

    // Glow animation state
    @State private var breathPhase: CGFloat = 0.4
    @State private var pulseIntensity: CGFloat = 0

    private let breathDuration: Double = 2.5

    var body: some View {
        VStack(spacing: 0) {
            TextField("Click here and start playing your notes", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .regular, design: .rounded))
                .lineLimit(3...12)
                .frame(maxWidth: .infinity)
                .padding(24)
                .focused($isFocused)
                .onChange(of: text) {
                    triggerPulse()
                    onKeyPress()
                }
        }
        .frame(width: 520)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.background.opacity(0.85))
        )
        .overlay(
            ZStack {
                // Outer soft glow
                RoundedRectangle(cornerRadius: 20)
                    .stroke(glowGradient, lineWidth: 2)
                    .blur(radius: 10 + pulseIntensity * 8)
                    .opacity(0.3 + breathPhase * 0.25 + pulseIntensity * 0.45)

                // Mid glow
                RoundedRectangle(cornerRadius: 20)
                    .stroke(glowGradient, lineWidth: 1.5)
                    .blur(radius: 4 + pulseIntensity * 3)
                    .opacity(0.45 + breathPhase * 0.25 + pulseIntensity * 0.35)

                // Crisp inner border
                RoundedRectangle(cornerRadius: 20)
                    .stroke(glowGradient, lineWidth: 0.8)
                    .opacity(0.5 + breathPhase * 0.2 + pulseIntensity * 0.3)
            }
        )
        .shadow(
            color: .white.opacity(0.15 + breathPhase * 0.08 + pulseIntensity * 0.2),
            radius: 18 + pulseIntensity * 12
        )
        .onAppear {
            startBreathing()
        }
    }

    // MARK: - Glow Colors

    /// Neutral white-to-silver gradient — adapts to light/dark mode
    private var glowGradient: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(0.9),
                Color(white: 0.75).opacity(0.7),
                .white.opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Animations

    private func startBreathing() {
        withAnimation(
            .easeInOut(duration: breathDuration)
            .repeatForever(autoreverses: true)
        ) {
            breathPhase = 1.0
        }
    }

    private func triggerPulse() {
        withAnimation(.easeIn(duration: 0.08)) {
            pulseIntensity = 1.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.08)) {
            pulseIntensity = 0
        }
    }
}
