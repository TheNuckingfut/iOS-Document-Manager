import Foundation
import Combine
import CoreData

/**
 * Document View Model
 *
 * This view model handles operations for a single document, providing a bridge between
 * the document entity in Core Data and the views that display or edit the document.
 *
 * It manages both local persistence and server synchronization for document operations,
 * and provides computed properties to help determine the current state of the document.
 *
 * Conforms to ObservableObject to integrate with SwiftUI's data flow system and
 * allow views to automatically update when the document changes.
 */
class DocumentViewModel: ObservableObject {
    /// The document entity this view model manages, published for SwiftUI reactivity
    @Published var document: DocumentEntity
    
    /// Set of cancellables to store and manage API request publishers
    private var cancellables = Set<AnyCancellable>()
    
    /**
     * Initializes a new DocumentViewModel with a specific document entity
     *
     * - Parameter document: The Core Data document entity to manage
     */
    init(document: DocumentEntity) {
        self.document = document
    }
    
    // MARK: - Document Status Helpers
    
    /**
     * Indicates whether the document is currently synchronized with the server
     *
     * - Returns: True if the document is synced, false if it needs creation, update, or deletion
     */
    var isSynced: Bool {
        document.syncStatus == DocumentSyncStatus.synced.rawValue
    }
    
    /**
     * Indicates whether the document needs to be synchronized with the server
     *
     * - Returns: True if the document needs to be created, updated, or deleted on the server
     */
    var needsSync: Bool {
        document.syncStatus != DocumentSyncStatus.synced.rawValue
    }
    
    /**
     * Provides a human-readable status text based on the document's sync status
     *
     * - Returns: A string describing the current synchronization status of the document
     */
    var statusText: String {
        switch document.syncStatus {
        case DocumentSyncStatus.synced.rawValue:
            return "Synced"
        case DocumentSyncStatus.needsCreate.rawValue:
            return "Pending Upload"
        case DocumentSyncStatus.needsUpdate.rawValue:
            return "Pending Update"
        case DocumentSyncStatus.needsDelete.rawValue:
            return "Pending Deletion"
        default:
            return "Unknown"
        }
    }
    
    // MARK: - Document Operations
    
    /**
     * Toggles the favorite status of the document
     *
     * This method:
     * 1. Toggles the isFavorite flag on the document
     * 2. Updates the modification date
     * 3. Marks the document for update on the server
     * 4. Saves the changes to Core Data
     * 5. Attempts to sync with the server if online
     */
    func toggleFavorite() {
        let context = CoreDataStack.shared.viewContext
        document.isFavorite.toggle()
        document.updatedAt = Date()
        document.markForUpdate()
        
        // Save to Core Data
        CoreDataStack.shared.saveContext()
        
        // Sync with server if online
        if NetworkMonitor.shared.isConnected {
            updateDocumentOnServer()
        }
    }
    
    /**
     * Updates the name of the document
     *
     * This method:
     * 1. Updates the document name
     * 2. Updates the modification date
     * 3. Marks the document for update on the server
     * 4. Saves the changes to Core Data
     * 5. Attempts to sync with the server if online
     *
     * - Parameter newName: The new name for the document
     */
    func updateName(_ newName: String) {
        let context = CoreDataStack.shared.viewContext
        document.name = newName
        document.updatedAt = Date()
        document.markForUpdate()
        
        // Save to Core Data
        CoreDataStack.shared.saveContext()
        
        // Sync with server if online
        if NetworkMonitor.shared.isConnected {
            updateDocumentOnServer()
        }
    }
    
    /**
     * Sends the updated document to the server
     *
     * This method is called automatically when changes are made and the device
     * is online. It converts the document to a DTO and calls the API service
     * to update it on the server. If successful, it updates the sync status.
     */
    func updateDocumentOnServer() {
        guard let id = document.id else { return }
        
        // Convert to DTO
        let documentDTO = document.toDTO()
        
        // Update on server
        APIService.shared.updateDocument(id: id, document: documentDTO)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    // Update sync status in Core Data
                    self.document.syncStatus = DocumentSyncStatus.synced.rawValue
                    CoreDataStack.shared.saveContext()
                case .failure(let error):
                    print("Failed to update document: \(error.localizedDescription)")
                    // Keep the sync status as needs update
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    /**
     * Deletes the document
     *
     * This method handles document deletion with different behavior based on connectivity:
     * - If offline: Marks the document for deletion and stores it in Core Data
     * - If online: Attempts to delete from the server first, then from Core Data if successful
     *
     * If the server deletion fails, the document is marked for deletion and will be
     * synchronized when connectivity is restored.
     */
    func delete() {
        guard let id = document.id else { return }
        
        // If offline, mark for deletion and wait for reconnection
        if !NetworkMonitor.shared.isConnected {
            document.markForDeletion()
            CoreDataStack.shared.saveContext()
            return
        }
        
        // Delete from server
        APIService.shared.deleteDocument(id: id)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    // Delete from Core Data
                    let context = CoreDataStack.shared.viewContext
                    context.delete(self.document)
                    CoreDataStack.shared.saveContext()
                case .failure(let error):
                    print("Failed to delete document: \(error.localizedDescription)")
                    // Mark for deletion for later sync
                    self.document.markForDeletion()
                    CoreDataStack.shared.saveContext()
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}
