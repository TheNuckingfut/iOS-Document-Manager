import SwiftUI

/**
 * Create Document View
 *
 * Provides a form for creating new documents.
 * Allows setting title, content, and file type.
 */
struct CreateDocumentView: View {
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var fileType: String = "txt"
    @State private var showFileTypeSelector = false
    @State private var showUploadAnimation = false
    
    let onSave: (String, String, String) -> Void
    let onCancel: () -> Void
    
    var isFormValid: Bool {
        !title.isEmpty && !content.isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if showUploadAnimation {
                    UploadAnimationView(
                        isComplete: $showUploadAnimation,
                        onComplete: {
                            onSave(title, content, fileType)
                        }
                    )
                } else {
                    Form {
                        Section(header: Text("Document Information")) {
                            TextField("Title", text: $title)
                                .padding(.vertical, 8)
                            
                            VStack(alignment: .leading) {
                                Text("File Type")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text(fileTypeDisplayName(fileType))
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        showFileTypeSelector = true
                                    }) {
                                        Text("Change")
                                            .font(.subheadline)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        Section(header: Text("Content")) {
                            TextEditor(text: $content)
                                .frame(minHeight: 200)
                        }
                        
                        Section {
                            HStack {
                                Button("Cancel", role: .cancel) {
                                    onCancel()
                                }
                                
                                Spacer()
                                
                                Button("Save") {
                                    showUploadAnimation = true
                                }
                                .disabled(!isFormValid)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Document")
            .actionSheet(isPresented: $showFileTypeSelector) {
                ActionSheet(
                    title: Text("Select File Type"),
                    buttons: [
                        .default(Text("Text File (.txt)")) { fileType = "txt" },
                        .default(Text("Word Document (.docx)")) { fileType = "docx" },
                        .default(Text("PDF Document (.pdf)")) { fileType = "pdf" },
                        .default(Text("Excel Spreadsheet (.xlsx)")) { fileType = "xlsx" },
                        .default(Text("PowerPoint Presentation (.pptx)")) { fileType = "pptx" },
                        .cancel()
                    ]
                )
            }
        }
    }
    
    /**
     * Convert file extension to display name
     *
     * - Parameter fileType: The file extension
     * - Returns: A user-friendly name for the file type
     */
    private func fileTypeDisplayName(_ fileType: String) -> String {
        switch fileType.lowercased() {
        case "pdf":
            return "PDF Document (.pdf)"
        case "doc", "docx":
            return "Word Document (.docx)"
        case "xls", "xlsx":
            return "Excel Spreadsheet (.xlsx)"
        case "ppt", "pptx":
            return "PowerPoint Presentation (.pptx)"
        case "txt":
            return "Text File (.txt)"
        default:
            return fileType.uppercased()
        }
    }
}

/**
 * Upload Animation View
 *
 * Displays a playful animation when uploading a document.
 * Shows progress and a celebration confetti effect on completion.
 */
struct UploadAnimationView: View {
    @Binding var isComplete: Bool
    let onComplete: () -> Void
    
    @State private var progress: CGFloat = 0
    @State private var showConfetti = false
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                if showConfetti {
                    ConfettiView()
                        .frame(height: 200)
                    
                    Text("Document Created!")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                        .padding()
                } else {
                    Text("Creating Document...")
                        .font(.title2)
                        .bold()
                        .padding()
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 300, height: 20)
                            .foregroundColor(Color.secondary.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 300 * progress, height: 20)
                            .foregroundColor(.blue)
                    }
                    
                    Text("\(Int(progress * 100))%")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if showConfetti {
                Button("Done") {
                    isComplete = false
                    onComplete()
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.systemBackground)
        .onAppear {
            // Simulate upload progress
            startProgressAnimation()
        }
    }
    
    /**
     * Animate the progress bar
     *
     * Simulates document upload with incremental progress updates.
     */
    private func startProgressAnimation() {
        let totalDuration: TimeInterval = 2.0 // 2 seconds for the animation
        let steps = 100
        let stepDuration = totalDuration / TimeInterval(steps)
        
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * TimeInterval(i)) {
                withAnimation {
                    self.progress = CGFloat(i) / CGFloat(steps)
                }
                
                if i == steps {
                    // Show confetti when complete
                    withAnimation {
                        self.showConfetti = true
                    }
                }
            }
        }
    }
}

/**
 * Confetti View
 *
 * Displays a colorful confetti animation for celebrations.
 */
struct ConfettiView: View {
    @State private var confetti: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confetti) { piece in
                piece.view
                    .position(piece.position)
                    .rotationEffect(piece.rotation)
                    .opacity(piece.opacity)
            }
        }
        .onAppear {
            createConfetti()
        }
    }
    
    /**
     * Generate confetti pieces
     *
     * Creates a random array of confetti with various shapes and colors.
     */
    private func createConfetti() {
        for i in 0..<100 {
            let position = CGPoint(
                x: CGFloat.random(in: 0...300),
                y: CGFloat.random(in: 0...0)
            )
            
            let rotation = Angle(degrees: Double.random(in: 0...360))
            let color = confettiColor()
            let shape = confettiShape(color: color)
            let size = CGFloat.random(in: 5...10)
            
            let piece = ConfettiPiece(
                id: i,
                position: position,
                rotation: rotation,
                shape: shape,
                color: color,
                size: size
            )
            
            confetti.append(piece)
            
            // Animate the confetti piece
            withAnimation(
                Animation.timingCurve(0.1, 1.0, 0.3, 1.0, duration: Double.random(in: 1.0...3.0))
            ) {
                confetti[i].position = CGPoint(
                    x: CGFloat.random(in: 0...300),
                    y: CGFloat.random(in: 150...200)
                )
                confetti[i].rotation = Angle(degrees: Double.random(in: 0...360))
            }
            
            // Fade out the confetti piece
            withAnimation(
                Animation.timingCurve(0.1, 1.0, 0.3, 1.0, duration: Double.random(in: 1.5...3.5))
            ) {
                confetti[i].opacity = 0
            }
        }
    }
    
    /**
     * Get a random confetti color
     *
     * - Returns: A random festive color
     */
    private func confettiColor() -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        return colors.randomElement() ?? .blue
    }
    
    /**
     * Create a random shape for confetti
     *
     * - Parameter color: The color to apply to the shape
     * - Returns: A view representing the confetti shape
     */
    private func confettiShape(color: Color) -> AnyView {
        let shapes = [
            AnyView(Circle().fill(color)),
            AnyView(Rectangle().fill(color)),
            AnyView(
                Image(systemName: "star.fill")
                    .foregroundColor(color)
            )
        ]
        return shapes.randomElement() ?? AnyView(Circle().fill(color))
    }
}

/**
 * Confetti Piece
 *
 * Represents a single piece of confetti with its properties.
 */
struct ConfettiPiece: Identifiable {
    let id: Int
    var position: CGPoint
    var rotation: Angle
    let shape: AnyView
    let color: Color
    let size: CGFloat
    var opacity: Double = 1.0
    
    /**
     * View representation of the confetti piece
     */
    var view: some View {
        shape
            .frame(width: size, height: size)
    }
}

/**
 * Extension to get system background color in SwiftUI
 */
extension Color {
    static var systemBackground: Color {
        Color(UIColor.systemBackground)
    }
}