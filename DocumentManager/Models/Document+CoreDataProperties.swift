import Foundation
import CoreData

extension Document {
    /**
     * Fetch request for Document entities
     *
     * - Returns: A fetch request for retrieving Document entities
     */
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Document> {
        return NSFetchRequest<Document>(entityName: "Document")
    }

    /**
     * Unique identifier for the document
     */
    @NSManaged public var id: String?
    
    /**
     * Title of the document
     */
    @NSManaged public var title: String?
    
    /**
     * Content of the document
     */
    @NSManaged public var content: String?
    
    /**
     * Creation date of the document
     */
    @NSManaged public var createdAt: Date?
    
    /**
     * Last update date of the document
     */
    @NSManaged public var updatedAt: Date?
    
    /**
     * Whether the document is marked as a favorite
     */
    @NSManaged public var isFavorite: Bool
    
    /**
     * Type of the document file (e.g., pdf, txt, doc)
     */
    @NSManaged public var fileType: String?
    
    /**
     * Size of the document in bytes
     */
    @NSManaged public var size: Int64
    
    /**
     * Array of tags associated with the document
     */
    @NSManaged public var tags: [String]?
    
    /**
     * Sync status of the document
     * 
     * 0 = synced, 1 = needsUpload, 2 = needsUpdate, 3 = needsDelete
     */
    @NSManaged public var syncStatus: Int16
}