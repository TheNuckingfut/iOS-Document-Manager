import Foundation
import CoreData

/**
 * Core Data Stack
 *
 * Manages the Core Data stack for persistent storage of documents.
 * Provides access to the managed object context and saves data.
 */
class CoreDataStack {
    static let shared = CoreDataStack()
    
    /**
     * Persistent container for the 'DocumentManager' model
     *
     * Manages the Core Data stack including the model, context, coordinator, and store.
     */
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DocumentManager")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        // For improved performance during batch operations
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    /**
     * Main view context for the app
     *
     * Used for fetching and updating managed objects on the main thread.
     */
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    /**
     * Background context for operations that should not block the main thread
     *
     * Used for operations like importing and syncing with the server.
     *
     * - Returns: A background managed object context
     */
    func createBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    /**
     * Save changes to the view context if there are changes
     *
     * Attempts to save the managed object context and logs any errors.
     */
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Error saving context: \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    /**
     * Save changes to a specific context
     *
     * - Parameter context: The managed object context to save
     * - Throws: An error if the save operation fails
     */
    func saveContext(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    /**
     * Perform an operation on a background context
     *
     * Executes an operation asynchronously on a background context
     * and saves the context if needed.
     *
     * - Parameter operation: The operation to perform
     */
    func performBackgroundTask(_ operation: @escaping (NSManagedObjectContext) -> Void) {
        let context = createBackgroundContext()
        context.perform {
            operation(context)
            
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    print("Error saving background context: \(error)")
                }
            }
        }
    }
    
    /**
     * Reset the Core Data stack
     *
     * Useful for testing or when the data model has significantly changed.
     */
    func resetAllData() {
        let persistentCoordinator = persistentContainer.persistentStoreCoordinator
        
        for store in persistentCoordinator.persistentStores {
            do {
                try persistentCoordinator.destroyPersistentStore(at: store.url!, ofType: store.type, options: nil)
            } catch {
                print("Error destroying persistent store: \(error)")
            }
        }
        
        // Recreate the persistent container
        do {
            try persistentCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: persistentContainer.persistentStoreDescriptions.first?.url, options: nil)
        } catch {
            print("Error recreating persistent store: \(error)")
        }
    }
}