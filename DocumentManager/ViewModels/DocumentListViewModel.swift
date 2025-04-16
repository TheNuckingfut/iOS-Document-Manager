import Foundation
import Combine
import CoreData
import SwiftUI

class DocumentListViewModel: ObservableObject {
    // Published properties
    @Published var documents: [DocumentEntity] = []
    @Published var favoriteDocuments: [DocumentEntity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    @Published var searchText = ""
    @Published var isCreatingDocument = false
    
    // State for document creation
    @Published var newDocumentName = ""
    @Published var newDocumentIsFavorite = false
    
    // Core Data fetch request
    private var documentsRequest: NSFetchRequest<DocumentEntity>
    private var favoritesRequest: NSFetchRequest<DocumentEntity>
    
    // Cancellables for networking
    private var cancellables = Set<AnyCancellable>()
    
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
                            if existingDocument.syncStatus == DocumentSyncStatus.synced.rawValue {
                                existingDocument.update(from: dto)
                            }
                        } else {
                            // Create new document entity
                            _ = DocumentEntity.from(dto: dto, in: context)
                        }
                    } catch {
                        print("Error syncing document \(dto.id): \(error)")
                    }
                }
                
                // Save changes
                CoreDataStack.shared.saveContext()
                
                // Reload documents from Core Data
                self.loadDocumentsFromCoreData()
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Document Operations
    
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
    
    func deleteDocument(_ document: DocumentEntity) {
        let viewModel = DocumentViewModel(document: document)
        viewModel.delete()
        
        // Reload documents from Core Data
        loadDocumentsFromCoreData()
    }
    
    // MARK: - Helper Methods
    
    private func resetNewDocumentFields() {
        newDocumentName = ""
        newDocumentIsFavorite = false
        isCreatingDocument = false
    }
    
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
    
    func search() {
        loadDocumentsFromCoreData()
    }
    
    func clearSearch() {
        searchText = ""
        loadDocumentsFromCoreData()
    }
}
