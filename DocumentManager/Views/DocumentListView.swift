import SwiftUI
import CoreData

struct DocumentListView: View {
    let documents: [DocumentEntity]
    @ObservedObject var viewModel: DocumentListViewModel
    let title: String
    var showEmptyFavorites: Bool = false
    
    @State private var documentToEdit: DocumentEntity?
    @State private var isEditSheetPresented = false
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                LoadingView()
            } else if !documents.isEmpty {
                documentsListContent
            } else {
                EmptyStateView(
                    message: showEmptyFavorites ? 
                        "No favorites yet. Star some documents to see them here!" : 
                        "No documents yet. Create one by tapping the plus button!",
                    systemImage: showEmptyFavorites ? "star" : "doc"
                )
            }
        }
        .navigationTitle(title)
        .navigationBarItems(
            leading: refreshButton,
            trailing: HStack {
                searchButton
                addButton
            }
        )
        .alert(isPresented: $viewModel.hasError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .searchable(text: $viewModel.searchText, prompt: "Search documents")
        .onChange(of: viewModel.searchText) { _ in
            viewModel.search()
        }
        .sheet(isPresented: $isEditSheetPresented) {
            if let document = documentToEdit {
                DocumentEditSheet(document: document, onDismiss: {
                    isEditSheetPresented = false
                    documentToEdit = nil
                    // Reload data after dismissal
                    viewModel.loadDocumentsFromCoreData()
                })
            }
        }
    }
    
    private var documentsListContent: some View {
        List {
            ForEach(documents, id: \.objectID) { document in
                DocumentCell(document: document)
                    .contextMenu {
                        Button(action: {
                            documentToEdit = document
                            isEditSheetPresented = true
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(action: {
                            let docVM = DocumentViewModel(document: document)
                            docVM.toggleFavorite()
                            viewModel.loadDocumentsFromCoreData()
                        }) {
                            Label(
                                document.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                systemImage: document.isFavorite ? "star.slash" : "star.fill"
                            )
                        }
                        
                        Button(role: .destructive, action: {
                            viewModel.deleteDocument(document)
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteDocument(document)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            documentToEdit = document
                            isEditSheetPresented = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
            }
        }
    }
    
    private var refreshButton: some View {
        Button(action: {
            viewModel.fetchDocumentsFromServer()
        }) {
            Image(systemName: "arrow.clockwise")
        }
    }
    
    private var searchButton: some View {
        Button(action: {
            // Activate search field
            UIApplication.shared.sendAction(
                #selector(UIResponder.becomeFirstResponder),
                to: nil, from: nil, for: nil
            )
        }) {
            Image(systemName: "magnifyingglass")
        }
    }
    
    private var addButton: some View {
        Button(action: {
            viewModel.isCreatingDocument = true
        }) {
            Image(systemName: "plus")
        }
    }
}
