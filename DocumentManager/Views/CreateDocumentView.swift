import SwiftUI

struct CreateDocumentView: View {
    @ObservedObject var viewModel: DocumentListViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
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
                    viewModel.createDocument()
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(viewModel.newDocumentName.isEmpty)
            )
        }
    }
}
