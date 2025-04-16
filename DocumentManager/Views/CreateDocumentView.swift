import SwiftUI

/**
 * Create Document View
 *
 * A form-based view that allows users to create new documents with a name
 * and favorite status. Includes an upload animation with confetti effect
 * when a document is successfully created.
 */
struct CreateDocumentView: View {
    /// View model providing document operations
    @ObservedObject var viewModel: DocumentListViewModel
    
    /// Environment value to dismiss the sheet
    @Environment(\.presentationMode) var presentationMode
    
    /// Current color scheme (light/dark mode)
    @Environment(\.colorScheme) var colorScheme
    
    /// Controls the visibility of the upload animation
    @State private var showUploadAnimation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main form
                Form {
                    Section(header: Text("Document Details")) {
                        TextField("Document Name", text: $viewModel.newDocumentName)
                            .font(.body)
                            .padding()
                            .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        Toggle("Mark as Favorite", isOn: $viewModel.newDocumentIsFavorite)
                            .font(.body)
                    }
                    
                    Section {
                        Text("Documents created while offline will be uploaded once the network connection is restored.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !NetworkMonitor.shared.isConnected {
                        Section {
                            HStack {
                                Image(systemName: "wifi.slash")
                                Text("You're offline")
                                Spacer()
                            }
                            .foregroundColor(.orange)
                        }
                    }
                }
                .navigationTitle("Create Document")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    },
                    trailing: Button("Create") {
                        createDocumentWithAnimation()
                    }
                    .disabled(viewModel.newDocumentName.isEmpty)
                )
                
                // Upload animation overlay
                UploadAnimationView(
                    isShowing: $showUploadAnimation,
                    documentName: viewModel.newDocumentName,
                    onComplete: {
                        // Dismiss the sheet after animation completes
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    /**
     * Creates a document with animation
     *
     * Shows the upload animation with confetti celebration,
     * then calls the view model to actually create the document.
     */
    private func createDocumentWithAnimation() {
        // Only proceed if we have a valid document name
        guard !viewModel.newDocumentName.isEmpty else { return }
        
        // Show the upload animation
        withAnimation {
            showUploadAnimation = true
        }
        
        // Actually create the document after a short delay
        // to give the animation time to appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            viewModel.createDocument()
        }
    }
}
