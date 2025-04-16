import Foundation
import Combine
import CoreData
import SwiftUI

/**
 * Document List View Model
 *
 * This view model manages collections of documents and related operations.
 * It serves as the primary data source for document list views, handling:
 * - Loading documents from Core Data and the server
 * - Creating new documents
 * - Searching and filtering documents
 * - Managing favorites
 * - Handling network state changes
 *
 * The view model uses the MVVM pattern to separate UI concerns from business logic
 * and data access, making the views more declarative and testable.
 */
class DocumentListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// All documents, sorted by update date (newest first)
    @Published var documents: [DocumentEntity] = []
    
    /// Only favorite documents, sorted by update date (newest first)
    @Published var favoriteDocuments: [DocumentEntity] = []
    
    /// Loading state indicator for UI feedback
    @Published var isLoading = false
    
    /// Error message to display if operations fail
    @Published var errorMessage: String?
    
    /// Flag indicating whether an error has occurred
    @Published var hasError = false
    
    /// Current search text for filtering documents
    @Published var searchText = ""
    
    /// Flag indicating whether the document creation UI should be shown
    @Published var isCreatingDocument = false
    
    // MARK: - Document Creation State
    
    /// Name for the new document being created
    @Published var newDocumentName = ""
    
    /// Favorite status for the new document being created
    @Published var newDocumentIsFavorite = false
    
    // MARK: - Private Properties
    
    /// Core Data fetch request for all documents
    private var documentsRequest: NSFetchRequest<DocumentEntity>
    
    /// Core Data fetch request for favorite documents
    private var favoritesRequest: NSFetchRequest<DocumentEntity>
    
    /// Set of cancellables to store and manage API request publishers
    private var cancellables = Set<AnyCancellable>()
    
    /**
     * Initializes the Document List View Model
     *
     * Sets up Core Data fetch requests, loads initial document data,
     * and configures network state monitoring for automatic synchronization.
     */
    init() {
        // Setup Core Data fetch requests
        documentsRequest = DocumentEntity.fetchRequest()
        documentsRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DocumentEntity.updatedAt, ascending: false)]
        
        favoritesRequest = DocumentEntity.fetchRequest()
        favoritesRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DocumentEntity.updatedAt, ascending: false)]
        favoritesRequest.predicate = NSPredicate(format: "isFavorite == YES")
        
        // Load initial data from Core Data
        loadDocumentsFromCoreData()
        
        // Setup network monitoring for automatic sync
        setupNetworkMonitoring()
    }
    
    // MARK: - Data Loading
    
    /**
     * Loads documents from Core Data into the view model
     *
     * This method is the primary way to populate the documents and favoriteDocuments
     * collections. It applies any active search filters and handles error reporting.
     *
     * Called at initialization, after data changes, and when search criteria change.
     */
    func loadDocumentsFromCoreData() {
        do {
            let context = CoreDataStack.shared.viewContext
            
            // If we have a search term, add it to the predicate
            if !searchText.isEmpty {
                documentsRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText)
                favoritesRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@ AND isFavorite == YES", searchText)
            } else {
                documentsRequest.predicate = nil
                favoritesRequest.predicate = NSPredicate(format: "isFavorite == YES")
            }
            
            // Fetch documents
            documents = try context.fetch(documentsRequest)
            favoriteDocuments = try context.fetch(favoritesRequest)
        } catch {
            self.errorMessage = "Failed to load documents: \(error.localizedDescription)"
            self.hasError = true
            print("Failed to fetch documents: \(error)")
        }
    }
    
    /**
     * Fetches documents from the remote server and updates local storage
     *
     * This method connects to the server through the API service, fetches the latest
     * documents, and updates the Core Data store using a smart sync strategy:
     * - For existing documents: updates only if they're not pending synchronization
     * - For new documents: creates new Core Data entities
     *
     * Handles loading states and error reporting for the UI.
     */
    func fetchDocumentsFromServer() {
        isLoading = true
        errorMessage = nil
        hasError = false
        
        APIService.shared.fetchDocuments()
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.errorMessage = "Failed to fetch documents: \(error.localizedDescription)"
                    self.hasError = true
                    print("Error fetching documents: \(error)")
                }
            }, receiveValue: { [weak self] documents in
                guard let self = self else { return }
                
                // Process received documents
                let context = CoreDataStack.shared.viewContext
                
                // Sync strategy: Update existing, create new
                for dto in documents {
                    // Check if document already exists
                    let fetchRequest: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id)
                    
                    do {
                        let results = try context.fetch(fetchRequest)
                        if let existingDocument = results.first {
                            // Only update if the document is not marked for sync
                            // This prevents overwriting local changes that haven't been synced yet
                            if existingDocument.syncStatus == DocumentSyncStatus.synced.rawValue {
                                existingDocument.update(from: dto)
                            }
                        } else {
                            // Create new document entity for documents that don't exist locally
                            _ = DocumentEntity.from(dto: dto, in: context)
                        }
                    } catch {
                        print("Error syncing document \(dto.id): \(error)")
                    }
                }
                
                // Save changes to Core Data
                CoreDataStack.shared.saveContext()
                
                // Reload documents from Core Data to refresh the UI
                self.loadDocumentsFromCoreData()
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Document Operations
    
    /**
     * Creates a new document
     *
     * This method creates a document both locally in Core Data and on the server.
     * It handles both online and offline scenarios:
     * - If online: Creates in Core Data and attempts to sync with the server
     * - If offline: Creates in Core Data and marks for later creation on the server
     *
     * Validates that the document name is not empty before proceeding.
     */
    func createDocument() {
        guard !newDocumentName.isEmpty else {
            errorMessage = "Document name cannot be empty"
            hasError = true
            return
        }
        
        // Create document in Core Data
        let context = CoreDataStack.shared.viewContext
        let newDocument = DocumentEntity(context: context)
        newDocument.id = UUID().uuidString
        newDocument.name = newDocumentName
        newDocument.isFavorite = newDocumentIsFavorite
        newDocument.createdAt = Date()
        newDocument.updatedAt = Date()
        
        // If offline, mark for creation later
        if !NetworkMonitor.shared.isConnected {
            newDocument.markForCreation()
            CoreDataStack.shared.saveContext()
            loadDocumentsFromCoreData()
            resetNewDocumentFields()
            return
        }
        
        // Create on server
        let dto = newDocument.toDTO()
        APIService.shared.createDocument(document: dto)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                case .finished:
                    // Mark as synced
                    newDocument.syncStatus = DocumentSyncStatus.synced.rawValue
                case .failure(let error):
                    print("Failed to create document on server: \(error)")
                    // Mark for creation later
                    newDocument.markForCreation()
                }
                
                // Save and reload
                CoreDataStack.shared.saveContext()
                self.loadDocumentsFromCoreData()
                self.resetNewDocumentFields()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    /**
     * Deletes a document
     *
     * This method delegates the deletion to the DocumentViewModel, which handles
     * the proper deletion logic based on connectivity status. After the deletion
     * process is initiated, it reloads the document lists to reflect the change.
     *
     * - Parameter document: The document entity to delete
     */
    func deleteDocument(_ document: DocumentEntity) {
        let viewModel = DocumentViewModel(document: document)
        viewModel.delete()
        
        // Reload documents from Core Data
        loadDocumentsFromCoreData()
    }
    
    // MARK: - Helper Methods
    
    /**
     * Resets the form fields for document creation
     *
     * Called after a document is created or when the creation is canceled.
     */
    private func resetNewDocumentFields() {
        newDocumentName = ""
        newDocumentIsFavorite = false
        isCreatingDocument = false
    }
    
    /**
     * Sets up network state monitoring
     *
     * Observes changes in network connectivity and triggers synchronization
     * when the device reconnects to the network. This ensures that any changes
     * made while offline are sent to the server when connectivity is restored.
     */
    private func setupNetworkMonitoring() {
        NetworkMonitor.shared.$isConnected
            .dropFirst() // Skip initial value
            .filter { $0 } // Only react to reconnections
            .sink { [weak self] _ in
                // When reconnected, sync pending changes
                SyncService.shared.syncPendingChanges()
                // Reload documents after sync
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self?.loadDocumentsFromCoreData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Search Functionality
    
    /**
     * Executes a search based on the current searchText
     *
     * Reloads documents from Core Data with filtering applied.
     */
    func search() {
        loadDocumentsFromCoreData()
    }
    
    /**
     * Clears the current search
     *
     * Resets the search text and reloads all documents.
     */
    func clearSearch() {
        searchText = ""
        loadDocumentsFromCoreData()
    }
}
