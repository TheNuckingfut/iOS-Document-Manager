import Foundation
import CoreData

/**
 * Sync Service
 *
 * Manages synchronization of documents between local storage and the server.
 * Handles offline operations and conflict resolution.
 */
class SyncService {
    static let shared = SyncService()
    
    /// The API service for communicating with the server
    private let apiService = APIService.shared
    
    /// A queue for synchronizing operations
    private let syncQueue = DispatchQueue(label: "com.documentmanager.syncqueue", qos: .utility)
    
    /// Indicates if a sync operation is currently in progress
    private var isSyncing = false
    
    /**
     * Sync all pending changes to the server
     *
     * Uploads, updates, or deletes documents based on their sync status.
     *
     * - Parameter completion: Closure called when sync is complete
     */
    func syncPendingChanges(completion: @escaping () -> Void = {}) {
        guard NetworkMonitor.shared.isConnected else {
            completion()
            return
        }
        
        // Prevent multiple sync operations from running concurrently
        syncQueue.async { [weak self] in
            guard let self = self, !self.isSyncing else {
                completion()
                return
            }
            
            self.isSyncing = true
            
            let group = DispatchGroup()
            
            // Fetch documents that need to be uploaded, updated, or deleted
            let context = CoreDataStack.shared.viewContext
            let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "syncStatus != 0") // Not synced
            
            do {
                let documents = try context.fetch(fetchRequest)
                
                for document in documents {
                    switch document.syncStatus {
                    case 1: // Needs Upload
                        group.enter()
                        self.uploadDocument(document) { _ in
                            group.leave()
                        }
                    case 2: // Needs Update
                        group.enter()
                        self.updateDocument(document) { _ in
                            group.leave()
                        }
                    case 3: // Needs Delete
                        group.enter()
                        self.deleteDocument(document) { _ in
                            group.leave()
                        }
                    default:
                        break
                    }
                }
                
                group.notify(queue: .main) {
                    self.isSyncing = false
                    completion()
                }
            } catch {
                print("Error fetching documents for sync: \(error)")
                self.isSyncing = false
                completion()
            }
        }
    }
    
    /**
     * Upload a document to the server
     *
     * Creates a new document on the server and updates local sync status.
     *
     * - Parameters:
     *   - document: The document to upload
     *   - completion: Closure called when upload is complete
     */
    func uploadDocument(_ document: Document, completion: @escaping (Bool) -> Void = { _ in }) {
        guard NetworkMonitor.shared.isConnected else {
            completion(false)
            return
        }
        
        let documentData = document.toDictionary()
        
        apiService.uploadDocument(documentData) { [weak self] result in
            switch result {
            case .success(let responseData):
                // Update document with server ID if needed
                if let serverDocumentId = responseData["id"] as? String {
                    self?.updateLocalDocumentAfterSync(document: document, serverId: serverDocumentId)
                }
                completion(true)
            case .failure(let error):
                print("Error uploading document: \(error)")
                completion(false)
            }
        }
    }
    
    /**
     * Update a document on the server
     *
     * Sends updated document data to the server.
     *
     * - Parameters:
     *   - document: The document to update
     *   - completion: Closure called when update is complete
     */
    func updateDocument(_ document: Document, completion: @escaping (Bool) -> Void = { _ in }) {
        guard NetworkMonitor.shared.isConnected, let documentId = document.id else {
            completion(false)
            return
        }
        
        let documentData = document.toDictionary()
        
        apiService.updateDocument(documentId: documentId, document: documentData) { [weak self] result in
            switch result {
            case .success(_):
                self?.updateLocalDocumentAfterSync(document: document)
                completion(true)
            case .failure(let error):
                print("Error updating document: \(error)")
                completion(false)
            }
        }
    }
    
    /**
     * Delete a document from the server
     *
     * Removes a document from the server and local storage.
     *
     * - Parameters:
     *   - document: The document to delete
     *   - completion: Closure called when deletion is complete
     */
    func deleteDocument(_ document: Document, completion: @escaping (Bool) -> Void = { _ in }) {
        guard NetworkMonitor.shared.isConnected, let documentId = document.id else {
            completion(false)
            return
        }
        
        apiService.deleteDocument(documentId: documentId) { [weak self] result in
            switch result {
            case .success(_):
                self?.removeLocalDocument(document)
                completion(true)
            case .failure(let error):
                print("Error deleting document: \(error)")
                completion(false)
            }
        }
    }
    
    /**
     * Update a local document after syncing with the server
     *
     * Updates the sync status and server ID of a document.
     *
     * - Parameters:
     *   - document: The document to update
     *   - serverId: Optional server-assigned ID for new documents
     */
    private func updateLocalDocumentAfterSync(document: Document, serverId: String? = nil) {
        CoreDataStack.shared.performBackgroundTask { context in
            // Need to get the document in this context
            let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
            
            if let documentId = document.id {
                fetchRequest.predicate = NSPredicate(format: "id == %@", documentId)
                
                do {
                    if let localDocument = try context.fetch(fetchRequest).first {
                        if let serverId = serverId {
                            localDocument.id = serverId
                        }
                        localDocument.syncStatus = 0 // Synced
                    }
                } catch {
                    print("Error updating local document after sync: \(error)")
                }
            }
        }
    }
    
    /**
     * Remove a document from local storage
     *
     * Deletes a document entity after successful server deletion.
     *
     * - Parameter document: The document to remove
     */
    private func removeLocalDocument(_ document: Document) {
        CoreDataStack.shared.performBackgroundTask { context in
            // Need to get the document in this context
            let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
            
            if let documentId = document.id {
                fetchRequest.predicate = NSPredicate(format: "id == %@", documentId)
                
                do {
                    if let localDocument = try context.fetch(fetchRequest).first {
                        context.delete(localDocument)
                    }
                } catch {
                    print("Error removing local document: \(error)")
                }
            }
        }
    }
}