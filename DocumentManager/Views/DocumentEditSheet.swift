import SwiftUI
import Combine

struct DocumentEditSheet: View {
    let document: DocumentEntity
    let onDismiss: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var documentName: String = ""
    @State private var isFavorite: Bool = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    private var documentViewModel: DocumentViewModel
    
    init(document: DocumentEntity, onDismiss: @escaping () -> Void) {
        self.document = document
        self.onDismiss = onDismiss
        self.documentViewModel = DocumentViewModel(document: document)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Document Details")) {
                    TextField("Document Name", text: $documentName)
                        .font(.body)
                        .padding()
                        .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .disabled(isProcessing)
                    
                    Toggle("Favorite", isOn: $isFavorite)
                        .font(.body)
                        .disabled(isProcessing)
                }
                
                Section(header: Text("Document Info")) {
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(formattedDate(document.createdAt))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Last Updated")
                        Spacer()
                        Text(formattedDate(document.updatedAt))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Sync Status")
                        Spacer()
                        Text(documentViewModel.statusText)
                            .foregroundColor(documentViewModel.isSynced ? .green : .orange)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Document")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                    onDismiss()
                },
                trailing: Button("Save") {
                    saveDocument()
                }
                .disabled(documentName.isEmpty || isProcessing)
            )
            .onAppear {
                // Initialize form values
                documentName = document.name ?? ""
                isFavorite = document.isFavorite
            }
        }
    }
    
    private func saveDocument() {
        if documentName.isEmpty {
            errorMessage = "Document name cannot be empty"
            return
        }
        
        isProcessing = true
        
        // Update document name if changed
        if documentName != document.name {
            documentViewModel.updateName(documentName)
        }
        
        // Update favorite status if changed
        if isFavorite != document.isFavorite {
            documentViewModel.toggleFavorite()
        }
        
        // Dismiss after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isProcessing = false
            presentationMode.wrappedValue.dismiss()
            onDismiss()
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
