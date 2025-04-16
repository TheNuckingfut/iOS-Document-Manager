import SwiftUI

/**
 * Confetti View
 *
 * A customizable view that displays a confetti animation effect.
 * This can be used to celebrate user actions like successful document uploads.
 */
struct ConfettiView: View {
    /// Controls whether the confetti animation is active
    @Binding var isActive: Bool
    
    /// Number of confetti pieces to display
    private let particleCount: Int
    
    /// Duration of the confetti animation in seconds
    private let duration: Double
    
    /// Optional completion handler to call when animation finishes
    private var onCompletion: (() -> Void)?
    
    /**
     * Initializes a new confetti view
     *
     * - Parameters:
     *   - isActive: Binding to control when the animation is active
     *   - particleCount: Number of confetti pieces (default 50)
     *   - duration: Animation duration in seconds (default 2.0)
     *   - onCompletion: Optional completion handler
     */
    init(
        isActive: Binding<Bool>,
        particleCount: Int = 50,
        duration: Double = 2.0,
        onCompletion: (() -> Void)? = nil
    ) {
        self._isActive = isActive
        self.particleCount = particleCount
        self.duration = duration
        self.onCompletion = onCompletion
    }
    
    /// The body of the confetti view
    var body: some View {
        ZStack {
            // Only display when active
            if isActive {
                ForEach(0..<particleCount, id: \.self) { index in
                    ConfettiParticle(
                        color: randomColor(),
                        position: randomPosition(),
                        angle: randomAngle(),
                        duration: duration
                    )
                }
                .onAppear {
                    // Automatically deactivate after the animation duration
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation {
                            isActive = false
                            onCompletion?()
                        }
                    }
                }
            }
        }
    }
    
    /// Generates a random color for confetti variation
    private func randomColor() -> Color {
        let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange]
        return colors.randomElement() ?? .blue
    }
    
    /// Generates a random starting position for a confetti particle
    private func randomPosition() -> CGPoint {
        return CGPoint(
            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
            y: -20 // Start slightly above the screen
        )
    }
    
    /// Generates a random angle for the confetti particle's rotation
    private func randomAngle() -> Double {
        return Double.random(in: 0...360)
    }
}

/**
 * Individual confetti particle
 *
 * Represents a single piece of confetti with its own color,
 * position, movement pattern and rotation.
 */
struct ConfettiParticle: View {
    /// The particle's color
    let color: Color
    
    /// The particle's starting position
    let position: CGPoint
    
    /// The particle's starting angle in degrees
    let angle: Double
    
    /// Duration of the particle's animation
    let duration: Double
    
    /// State for the animation progress (0 to 1)
    @State private var animationProgress: Double = 0
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .position(
                x: position.x + CGFloat(sin(angle) * 100 * animationProgress),
                y: position.y + CGFloat(UIScreen.main.bounds.height * animationProgress)
            )
            .rotationEffect(.degrees(angle * animationProgress * 2))
            .opacity(1 - animationProgress)
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    animationProgress = 1.0
                }
            }
    }
}

// MARK: - Preview
struct ConfettiView_Previews: PreviewProvider {
    // Preview with a button to trigger the animation
    private struct ConfettiPreview: View {
        @State private var showConfetti = false
        
        var body: some View {
            ZStack {
                Button("Show Confetti") {
                    showConfetti = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                ConfettiView(isActive: $showConfetti)
            }
        }
    }
    
    static var previews: some View {
        ConfettiPreview()
    }
}