import Foundation
import CoreData

/**
 * Core Data Stack
 *
 * Manages the Core Data stack for the application, providing access to the persistent
 * store coordinator, managed object model, and managed object contexts.
 *
 * Implemented as a singleton to ensure a single source of truth for data persistence.
 */
class CoreDataStack {
    /// Shared instance of the CoreDataStack (Singleton)
    static let shared = CoreDataStack()
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - Core Data Stack
    
    /**
     * The persistent container for the application.
     *
     * This property lazily loads the Core Data stack, including the
     * model, coordinator, and context. It ensures the persistent store
     * is properly configured and handles store loading errors.
     */
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DocumentManager")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // In a production app, we might want to handle this more gracefully
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    /**
     * The main managed object context associated with the main queue.
     *
     * This context should be used for UI-related operations and
     * for fetching data to display in the app.
     */
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    /**
     * Creates a new background context for operations that should not block the UI.
     *
     * - Returns: A new NSManagedObjectContext associated with a private queue
     */
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Core Data Saving Support
    
    /**
     * Saves changes in the view context if there are any pending changes.
     *
     * This method should be called when appropriate to persist changes
     * to the Core Data store, such as when the application enters background,
     * before termination, or after completing a batch of changes.
     */
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /**
     * Fetches documents from the Core Data store with an optional predicate.
     *
     * - Parameter predicate: Optional NSPredicate to filter documents (nil returns all documents)
     * - Returns: Array of DocumentEntity objects matching the predicate, sorted by update date (newest first)
     */
    func fetchDocuments(withPredicate predicate: NSPredicate? = nil) -> [DocumentEntity] {
        let fetchRequest: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DocumentEntity.updatedAt, ascending: false)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch documents: \(error)")
            return []
        }
    }
    
    /**
     * Fetches a specific document by its unique identifier.
     *
     * - Parameter id: The unique identifier of the document to fetch
     * - Returns: The DocumentEntity if found, or nil if not found
     */
    func fetchDocument(withID id: String) -> DocumentEntity? {
        let fetchRequest: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            return results.first
        } catch {
            print("Failed to fetch document: \(error)")
            return nil
        }
    }
    
    /**
     * Deletes a document from the Core Data store.
     *
     * - Parameter document: The DocumentEntity to delete
     *
     * This method immediately saves the context after deletion to ensure
     * the change is persisted to the store.
     */
    func deleteDocument(_ document: DocumentEntity) {
        viewContext.delete(document)
        saveContext()
    }
}
