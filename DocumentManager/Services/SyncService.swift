import Foundation
import Combine
import CoreData

class SyncService {
    static let shared = SyncService()
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Sync Operations
    
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
