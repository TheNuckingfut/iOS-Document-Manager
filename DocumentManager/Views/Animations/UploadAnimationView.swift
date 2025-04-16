import SwiftUI
import UIKit

/**
 * Upload Animation View
 *
 * A playful animation that shows a document being uploaded.
 * Includes a success state with confetti celebration when upload completes.
 */
struct UploadAnimationView: View {
    /// Controls whether the animation is visible
    @Binding var isShowing: Bool
    
    /// Controls the animation progress (0 to 1)
    @State private var progress: CGFloat = 0
    
    /// Tracks when the upload animation is complete
    @State private var isComplete: Bool = false
    
    /// Controls the confetti celebration
    @State private var showConfetti: Bool = false
    
    /// Optional completion handler
    var onComplete: (() -> Void)?
    
    /// Document name to display in the animation
    var documentName: String
    
    var body: some View {
        ZStack {
            // Semi-transparent background overlay
            if isShowing {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .onTapGesture {
                        // Allow dismissing after completion
                        if isComplete {
                            withAnimation {
                                isShowing = false
                            }
                        }
                    }
                
                // Animation container
                VStack(spacing: 20) {
                    // Document icon
                    Image(systemName: isComplete ? "doc.fill.badge.plus" : "doc")
                        .font(.system(size: 60))
                        .foregroundColor(isComplete ? .green : .blue)
                        .scaleEffect(isComplete ? 1.2 : 1.0)
                        .animation(.spring(), value: isComplete)
                    
                    // Document name
                    Text(documentName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !isComplete {
                        // Progress text
                        Text("\(Int(progress * 100))%")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.primary)
                        
                        // Progress bar
                        ProgressBar(progress: progress)
                            .frame(height: 8)
                            .padding(.horizontal, 40)
                    } else {
                        // Success message
                        Text("Upload Complete!")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.green)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Done button (only shown when complete)
                    if isComplete {
                        Button("Done") {
                            withAnimation {
                                isShowing = false
                                onComplete?()
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(radius: 10)
                )
                .padding(40)
                .transition(.scale.combined(with: .opacity))
                
                // Overlay the confetti on top
                ConfettiView(isActive: $showConfetti)
            }
        }
        .animation(.spring(), value: isShowing)
        .onChange(of: isShowing) { newValue in
            if newValue {
                startAnimation()
            }
        }
    }
    
    /**
     * Starts the upload animation sequence
     *
     * This method simulates a document upload with incrementing progress
     * and triggers the confetti effect when complete.
     */
    private func startAnimation() {
        // Reset states
        progress = 0
        isComplete = false
        showConfetti = false
        
        // Animate progress over time
        withAnimation(.easeInOut(duration: 2.0)) {
            progress = 1.0
        }
        
        // Mark as complete after progress animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            withAnimation {
                isComplete = true
                
                // Show confetti celebration
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showConfetti = true
                }
            }
        }
    }
}

/**
 * Progress Bar View
 *
 * A custom progress bar with rounded corners and a fill animation.
 */
struct ProgressBar: View {
    /// The progress value from 0 to 1
    var progress: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * progress, height: geometry.size.height)
            }
        }
    }
}

// MARK: - Preview
struct UploadAnimationView_Previews: PreviewProvider {
    private struct UploadAnimationPreview: View {
        @State private var showAnimation = false
        
        var body: some View {
            ZStack {
                VStack {
                    Button("Show Upload Animation") {
                        showAnimation = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                UploadAnimationView(
                    isShowing: $showAnimation,
                    documentName: "Project Report.pdf"
                )
            }
        }
    }
    
    static var previews: some View {
        UploadAnimationPreview()
    }
}