import Foundation
import CoreData

/**
 * Document Data Transfer Object (DTO)
 *
 * This struct represents the document data as it appears in the API.
 * It acts as an intermediary between the server data format and the CoreData model.
 * Conforming to Codable allows it to be easily serialized for API requests/responses.
 * Conforming to Identifiable allows it to be used in SwiftUI lists.
 */
struct DocumentDTO: Codable, Identifiable {
    /// Unique identifier for the document
    let id: String
    
    /// Name/title of the document
    var name: String
    
    /// Whether the document is marked as a favorite
    var isFavorite: Bool
    
    /// When the document was initially created
    var createdAt: Date
    
    /// When the document was last modified
    var updatedAt: Date
    
    /// Maps Swift property names to JSON keys in the API
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/**
 * Document Synchronization Status
 *
 * Represents the synchronization state of a document between local storage and the remote server.
 * Stored as Int16 to be compatible with CoreData.
 */
enum DocumentSyncStatus: Int16 {
    /// Document is in sync with the server
    case synced = 0
    
    /// Document exists locally but needs to be created on the server
    case needsCreate = 1
    
    /// Document has been modified locally and needs to be updated on the server
    case needsUpdate = 2
    
    /// Document has been deleted locally and needs to be deleted from the server
    case needsDelete = 3
}

/**
 * Document CoreData extensions
 *
 * Provides utility methods to convert between CoreData entities and DTOs,
 * as well as managing the synchronization status of documents.
 */
extension DocumentEntity {
    /**
     * Converts a CoreData Document entity to a DTO for API operations
     *
     * - Returns: A DocumentDTO representation of this entity
     */
    func toDTO() -> DocumentDTO {
        return DocumentDTO(
            id: self.id ?? UUID().uuidString,
            name: self.name ?? "Untitled",
            isFavorite: self.isFavorite,
            createdAt: self.createdAt ?? Date(),
            updatedAt: self.updatedAt ?? Date()
        )
    }
    
    /**
     * Creates a new DocumentEntity from a DTO
     *
     * - Parameters:
     *   - dto: The DocumentDTO to convert
     *   - context: The NSManagedObjectContext to create the entity in
     * - Returns: A new DocumentEntity
     */
    static func from(dto: DocumentDTO, in context: NSManagedObjectContext) -> DocumentEntity {
        let document = DocumentEntity(context: context)
        document.id = dto.id
        document.name = dto.name
        document.isFavorite = dto.isFavorite
        document.createdAt = dto.createdAt
        document.updatedAt = dto.updatedAt
        document.syncStatus = DocumentSyncStatus.synced.rawValue
        return document
    }
    
    /**
     * Updates an existing DocumentEntity with values from a DTO
     *
     * - Parameter dto: The DocumentDTO containing updated values
     */
    func update(from dto: DocumentDTO) {
        self.name = dto.name
        self.isFavorite = dto.isFavorite
        self.updatedAt = dto.updatedAt
        self.syncStatus = DocumentSyncStatus.synced.rawValue
    }
    
    /**
     * Marks the document as needing to be created on the server
     * Used when a document is created locally while offline
     */
    func markForCreation() {
        self.syncStatus = DocumentSyncStatus.needsCreate.rawValue
    }
    
    /**
     * Marks the document as needing to be updated on the server
     * Used when a document is modified locally while offline
     */
    func markForUpdate() {
        self.syncStatus = DocumentSyncStatus.needsUpdate.rawValue
    }
    
    /**
     * Marks the document as needing to be deleted from the server
     * Used when a document is deleted locally while offline
     */
    func markForDeletion() {
        self.syncStatus = DocumentSyncStatus.needsDelete.rawValue
    }
}
