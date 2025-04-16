import Foundation
import Combine
import CoreData

/**
 * Document List View Model
 *
 * Manages the list of documents displayed in the UI.
 * Handles fetching, filtering, and updating documents.
 */
class DocumentListViewModel: ObservableObject {
    /// Published array of documents for the view to display
    @Published var documents: [DocumentViewModel] = []
    
    /// Published array of favorite documents
    @Published var favoriteDocuments: [DocumentViewModel] = []
    
    /// Published loading state
    @Published var isLoading: Bool = false
    
    /// Published error message if something goes wrong
    @Published var errorMessage: String?
    
    /// Published search text for filtering documents
    @Published var searchText: String = ""
    
    /// The API service for fetching documents from the server
    private let apiService = APIService.shared
    
    /// The sync service for managing online/offline sync
    private let syncService = SyncService.shared
    
    /// Set of cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Filter predicate based on search text
    private var filterPredicate: NSPredicate? {
        if searchText.isEmpty {
            return nil
        }
        
        return NSPredicate(format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@", searchText, searchText)
    }
    
    /**
     * Initialize the view model
     *
     * Sets up subscriptions to search text changes and loads documents.
     */
    init() {
        // Subscribe to search text changes to update filtered documents
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.fetchDocuments()
            }
            .store(in: &cancellables)
        
        // Initial load of documents
        fetchDocuments()
        
        // Subscribe to network status changes
        NotificationCenter.default.publisher(for: .networkStatusDidChange)
            .sink { [weak self] _ in
                if NetworkMonitor.shared.isConnected {
                    self?.syncDocuments()
                }
            }
            .store(in: &cancellables)
    }
    
    /**
     * Fetch documents from Core Data
     *
     * Retrieves documents from local storage and updates the published document arrays.
     */
    func fetchDocuments() {
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        
        // Apply search filter if there is search text
        if let filterPredicate = filterPredicate {
            fetchRequest.predicate = filterPredicate
        }
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)]
        
        do {
            let documents = try CoreDataStack.shared.viewContext.fetch(fetchRequest)
            self.documents = documents.map { DocumentViewModel(document: $0) }
            self.favoriteDocuments = self.documents.filter { $0.isFavorite }
        } catch {
            self.errorMessage = "Failed to fetch documents: \(error.localizedDescription)"
            print("Error fetching documents: \(error)")
        }
    }
    
    /**
     * Synchronize documents with the server
     *
     * Fetches documents from the API and updates local storage.
     * Also sends any pending local changes to the server.
     */
    func syncDocuments() {
        guard NetworkMonitor.shared.isConnected else {
            return
        }
        
        isLoading = true
        
        // First, try to sync any pending changes
        syncService.syncPendingChanges { [weak self] in
            // Then, fetch the latest documents from the server
            self?.apiService.fetchDocuments { result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    switch result {
                    case .success(let documents):
                        self?.updateLocalDocuments(with: documents)
                        self?.fetchDocuments() // Refresh the UI with latest data
                    case .failure(let error):
                        self?.errorMessage = "Failed to sync: \(error.localizedDescription)"
                        print("Error syncing documents: \(error)")
                    }
                }
            }
        }
    }
    
    /**
     * Update local documents with data from the server
     *
     * Processes document data from the API and updates Core Data entities.
     *
     * - Parameter documents: Array of document data from the server
     */
    private func updateLocalDocuments(with documents: [[String: Any]]) {
        CoreDataStack.shared.performBackgroundTask { context in
            for documentData in documents {
                if let id = documentData["id"] as? String {
                    // Check if document already exists
                    let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", id)
                    
                    do {
                        let existingDocuments = try context.fetch(fetchRequest)
                        
                        let document: Document
                        
                        if let existingDocument = existingDocuments.first {
                            // Only update if the server version is newer
                            if let serverUpdatedAt = documentData["updatedAt"] as? Date,
                               let localUpdatedAt = existingDocument.updatedAt,
                               serverUpdatedAt > localUpdatedAt {
                                document = existingDocument
                            } else {
                                continue // Skip this document as local version is newer
                            }
                        } else {
                            // Create new document
                            document = Document(context: context)
                            document.id = id
                        }
                        
                        // Update document properties
                        document.title = documentData["title"] as? String
                        document.content = documentData["content"] as? String
                        document.createdAt = documentData["createdAt"] as? Date ?? Date()
                        document.updatedAt = documentData["updatedAt"] as? Date ?? Date()
                        document.fileType = documentData["fileType"] as? String
                        document.size = documentData["size"] as? Int64 ?? 0
                        document.tags = documentData["tags"] as? [String]
                        document.syncStatus = 0 // Synced
                    } catch {
                        print("Error updating document \(id): \(error)")
                    }
                }
            }
        }
    }
    
    /**
     * Add a new document
     *
     * Creates a new document and saves it to Core Data.
     * Also schedules it for upload to the server.
     *
     * - Parameters:
     *   - title: The title of the document
     *   - content: The content of the document
     *   - fileType: The type of file (e.g., "txt", "pdf")
     */
    func addDocument(title: String, content: String, fileType: String) {
        let context = CoreDataStack.shared.viewContext
        let document = Document(context: context)
        
        document.id = UUID().uuidString
        document.title = title
        document.content = content
        document.fileType = fileType
        document.createdAt = Date()
        document.updatedAt = Date()
        document.size = Int64(content.utf8.count)
        document.isFavorite = false
        document.syncStatus = 1 // Needs Upload
        
        do {
            try context.save()
            
            // Refresh UI
            fetchDocuments()
            
            // Try to sync if online
            if NetworkMonitor.shared.isConnected {
                syncService.uploadDocument(document)
            }
        } catch {
            self.errorMessage = "Failed to save document: \(error.localizedDescription)"
            print("Error saving document: \(error)")
        }
    }
    
    /**
     * Delete a document
     *
     * Removes a document from Core Data and schedules deletion on the server.
     *
     * - Parameter document: The view model of the document to delete
     */
    func deleteDocument(_ document: DocumentViewModel) {
        guard let id = document.id else { return }
        
        let context = CoreDataStack.shared.viewContext
        
        // Find the Core Data entity
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            if let documentEntity = try context.fetch(fetchRequest).first {
                if NetworkMonitor.shared.isConnected {
                    // If online, mark for deletion (will be synced)
                    documentEntity.syncStatus = 3 // Needs Delete
                    try context.save()
                    syncService.deleteDocument(documentEntity)
                } else {
                    // If offline, mark for deletion for later sync
                    documentEntity.syncStatus = 3 // Needs Delete
                    try context.save()
                }
                
                // Refresh UI
                fetchDocuments()
            }
        } catch {
            self.errorMessage = "Failed to delete document: \(error.localizedDescription)"
            print("Error deleting document: \(error)")
        }
    }
    
    /**
     * Toggle favorite status of a document
     *
     * Marks a document as favorite or removes favorite status.
     *
     * - Parameter document: The view model of the document to update
     */
    func toggleFavorite(_ document: DocumentViewModel) {
        guard let id = document.id else { return }
        
        let context = CoreDataStack.shared.viewContext
        
        // Find the Core Data entity
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            if let documentEntity = try context.fetch(fetchRequest).first {
                documentEntity.isFavorite.toggle()
                documentEntity.syncStatus = 2 // Needs Update
                try context.save()
                
                // Refresh UI
                fetchDocuments()
                
                // Sync change if online
                if NetworkMonitor.shared.isConnected {
                    syncService.updateDocument(documentEntity)
                }
            }
        } catch {
            self.errorMessage = "Failed to update favorite status: \(error.localizedDescription)"
            print("Error updating favorite status: \(error)")
        }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let networkStatusDidChange = Notification.Name("networkStatusDidChange")
}