import SwiftUI

/**
 * Main Tab View
 *
 * The root view of the app containing the tab bar and main navigation.
 * Provides access to the Home and Favorites views.
 */
struct MainTabView: View {
    @ObservedObject var viewModel: DocumentListViewModel
    @State private var selectedTab = 0
    @State private var showCreateDocumentSheet = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationView {
                DocumentListView(
                    documents: viewModel.documents,
                    isLoading: viewModel.isLoading,
                    errorMessage: viewModel.errorMessage,
                    onRefresh: { viewModel.syncDocuments() },
                    onDelete: { document in viewModel.deleteDocument(document) },
                    onToggleFavorite: { document in viewModel.toggleFavorite(document) }
                )
                .navigationTitle("Documents")
                .navigationBarItems(
                    trailing: Button(action: {
                        showCreateDocumentSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                )
            }
            .tabItem {
                Image(systemName: "doc.text")
                Text("Home")
            }
            .tag(0)
            
            // Favorites Tab
            NavigationView {
                DocumentListView(
                    documents: viewModel.favoriteDocuments,
                    isLoading: viewModel.isLoading,
                    errorMessage: viewModel.errorMessage,
                    onRefresh: { viewModel.syncDocuments() },
                    onDelete: { document in viewModel.deleteDocument(document) },
                    onToggleFavorite: { document in viewModel.toggleFavorite(document) }
                )
                .navigationTitle("Favorites")
            }
            .tabItem {
                Image(systemName: "star.fill")
                Text("Favorites")
            }
            .tag(1)
        }
        .accentColor(.blue)
        .sheet(isPresented: $showCreateDocumentSheet) {
            CreateDocumentView(
                onSave: { title, content, fileType in
                    viewModel.addDocument(
                        title: title,
                        content: content,
                        fileType: fileType
                    )
                    showCreateDocumentSheet = false
                },
                onCancel: {
                    showCreateDocumentSheet = false
                }
            )
        }
        .onAppear {
            // Initial sync when the view appears
            viewModel.syncDocuments()
        }
    }
}

/**
 * Document List View
 *
 * Displays a list of documents with swipe actions for delete and favorite.
 * Shows loading indicators and error messages when appropriate.
 */
struct DocumentListView: View {
    let documents: [DocumentViewModel]
    let isLoading: Bool
    let errorMessage: String?
    let onRefresh: () -> Void
    let onDelete: (DocumentViewModel) -> Void
    let onToggleFavorite: (DocumentViewModel) -> Void
    
    @State private var searchText = ""
    @State private var showingErrorAlert = false
    @State private var selectedDocument: DocumentViewModel?
    @State private var showDocumentDetail = false
    
    var body: some View {
        ZStack {
            if isLoading && documents.isEmpty {
                ProgressView("Loading documents...")
            } else if documents.isEmpty {
                VStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("No documents found")
                        .font(.headline)
                    
                    if NetworkMonitor.shared.isConnected {
                        Text("Pull down to refresh")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        Text("You're offline")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
            } else {
                List {
                    ForEach(documents) { document in
                        DocumentRow(document: document)
                            .onTapGesture {
                                selectedDocument = document
                                showDocumentDetail = true
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    onToggleFavorite(document)
                                } label: {
                                    Label(
                                        document.isFavorite ? "Remove Favorite" : "Favorite",
                                        systemImage: document.isFavorite ? "star.slash" : "star.fill"
                                    )
                                }
                                .tint(.yellow)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    onDelete(document)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .refreshable {
                    onRefresh()
                }
                .overlay(
                    Group {
                        if isLoading {
                            ProgressView()
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(10)
                        }
                    },
                    alignment: .center
                )
            }
        }
        .alert(isPresented: $showingErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: errorMessage) { newValue in
            showingErrorAlert = newValue != nil
        }
        .sheet(isPresented: $showDocumentDetail) {
            if let document = selectedDocument {
                DocumentDetailView(document: document)
            }
        }
    }
}

/**
 * Document Row
 *
 * A row in the document list showing document metadata.
 */
struct DocumentRow: View {
    let document: DocumentViewModel
    
    var body: some View {
        HStack {
            Image(systemName: document.iconName)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.headline)
                
                HStack {
                    Text(document.fileTypeDisplayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(document.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(document.formattedUpdateDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if document.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
            
            if document.syncStatus != 0 {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

/**
 * Document Detail View
 *
 * Shows the full details of a document and allows editing.
 */
struct DocumentDetailView: View {
    @ObservedObject var document: DocumentViewModel
    @State private var isEditing = false
    @State private var editedContent: String = ""
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(document.title)
                        .font(.title)
                        .bold()
                    
                    HStack {
                        Text(document.fileTypeDisplayName)
                            .font(.subheadline)
                        
                        Text("•")
                        
                        Text(document.formattedSize)
                            .font(.subheadline)
                        
                        if document.syncStatus != 0 {
                            Text("•")
                            
                            Text(document.syncStatusText)
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    document.isFavorite.toggle()
                    document.updateDocument()
                }) {
                    Image(systemName: document.isFavorite ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(document.isFavorite ? .yellow : .gray)
                }
            }
            .padding()
            
            Divider()
            
            if isEditing {
                TextEditor(text: $editedContent)
                    .padding()
                    .font(.body)
                
                HStack {
                    Button("Cancel") {
                        isEditing = false
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Spacer()
                    
                    Button("Save") {
                        document.content = editedContent
                        document.size = Int64(editedContent.utf8.count)
                        document.updateDocument()
                        isEditing = false
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                }
                .padding()
            } else {
                ScrollView {
                    Text(document.content)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button("Edit") {
                    editedContent = document.content
                    isEditing = true
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .padding()
            }
        }
        .navigationTitle("Document Details")
    }
}