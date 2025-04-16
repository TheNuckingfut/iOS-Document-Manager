import Foundation
import Combine
import CoreData

class DocumentViewModel: ObservableObject {
    @Published var document: DocumentEntity
    private var cancellables = Set<AnyCancellable>()
    
    init(document: DocumentEntity) {
        self.document = document
    }
    
    // Helper to determine document status
    var isSynced: Bool {
        document.syncStatus == DocumentSyncStatus.synced.rawValue
    }
    
    var needsSync: Bool {
        document.syncStatus != DocumentSyncStatus.synced.rawValue
    }
    
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
