import Foundation
import Combine
import CoreData

/**
 * Sync Service
 *
 * Responsible for synchronizing local document changes with the remote server.
 * This service handles the synchronization logic for documents that were created,
 * updated, or deleted while the device was offline.
 *
 * It works in conjunction with the NetworkMonitor to determine when syncing is possible,
 * and with the APIService to perform the actual server operations.
 */
class SyncService {
    /// Shared singleton instance of the SyncService
    static let shared = SyncService()
    
    /// Set of cancellables to store and manage ongoing API request publishers
    private var cancellables = Set<AnyCancellable>()
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - Sync Operations
    
    /**
     * Synchronizes all pending document changes with the server
     *
     * This method checks for documents that need to be created, updated,
     * or deleted on the server based on their sync status, and performs
     * the appropriate API operations.
     *
     * Only runs if the device has an active network connection.
     */
    func syncPendingChanges() {
        // Only sync if we're online
        guard NetworkMonitor.shared.isConnected else {
            print("Not connected to the internet, skipping sync")
            return
        }
        
        syncCreations()
        syncUpdates()
        syncDeletions()
    }
    
    // MARK: - Private Sync Methods
    
    /**
     * Synchronizes documents that need to be created on the server
     *
     * This method finds all documents with a syncStatus of 'needsCreate',
     * sends them to the server via the API service, and updates their
     * sync status to 'synced' if the operation succeeds.
     *
     * If the creation fails, the document remains marked for creation
     * and will be retried in future sync operations.
     */
    private func syncCreations() {
        // Find documents that need to be created on the server
        let creationPredicate = NSPredicate(format: "syncStatus == %d", DocumentSyncStatus.needsCreate.rawValue)
        let documentsToCreate = CoreDataStack.shared.fetchDocuments(withPredicate: creationPredicate)
        
        for document in documentsToCreate {
            let dto = document.toDTO()
            
            APIService.shared.createDocument(document: dto)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        // Update sync status
                        document.syncStatus = DocumentSyncStatus.synced.rawValue
                        CoreDataStack.shared.saveContext()
                    case .failure(let error):
                        print("Failed to sync creation: \(error.localizedDescription)")
                        // Keep marked for creation
                    }
                }, receiveValue: { _ in })
                .store(in: &cancellables)
        }
    }
    
    /**
     * Synchronizes documents that need to be updated on the server
     *
     * This method finds all documents with a syncStatus of 'needsUpdate',
     * sends their updated data to the server via the API service, and updates
     * their sync status to 'synced' if the operation succeeds.
     *
     * If the update fails, the document remains marked for update
     * and will be retried in future sync operations.
     */
    private func syncUpdates() {
        // Find documents that need to be updated on the server
        let updatePredicate = NSPredicate(format: "syncStatus == %d", DocumentSyncStatus.needsUpdate.rawValue)
        let documentsToUpdate = CoreDataStack.shared.fetchDocuments(withPredicate: updatePredicate)
        
        for document in documentsToUpdate {
            guard let id = document.id else { continue }
            let dto = document.toDTO()
            
            APIService.shared.updateDocument(id: id, document: dto)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        // Update sync status
                        document.syncStatus = DocumentSyncStatus.synced.rawValue
                        CoreDataStack.shared.saveContext()
                    case .failure(let error):
                        print("Failed to sync update: \(error.localizedDescription)")
                        // Keep marked for update
                    }
                }, receiveValue: { _ in })
                .store(in: &cancellables)
        }
    }
    
    /**
     * Synchronizes documents that need to be deleted from the server
     *
     * This method finds all documents with a syncStatus of 'needsDelete',
     * sends delete requests to the server via the API service, and completely
     * removes them from Core Data if the operation succeeds.
     *
     * If the deletion fails, the document remains marked for deletion
     * and will be retried in future sync operations.
     */
    private func syncDeletions() {
        // Find documents that need to be deleted from the server
        let deletionPredicate = NSPredicate(format: "syncStatus == %d", DocumentSyncStatus.needsDelete.rawValue)
        let documentsToDelete = CoreDataStack.shared.fetchDocuments(withPredicate: deletionPredicate)
        
        for document in documentsToDelete {
            guard let id = document.id else { continue }
            
            APIService.shared.deleteDocument(id: id)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        // Delete from core data
                        CoreDataStack.shared.deleteDocument(document)
                    case .failure(let error):
                        print("Failed to sync deletion: \(error.localizedDescription)")
                        // Keep marked for deletion
                    }
                }, receiveValue: { _ in })
                .store(in: &cancellables)
        }
    }
}
