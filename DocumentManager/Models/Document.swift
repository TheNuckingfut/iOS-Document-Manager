import Foundation
import CoreData

// MARK: - Document Struct (For API)
struct DocumentDTO: Codable, Identifiable {
    let id: String
    var name: String
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Document Status Enum
enum DocumentSyncStatus: Int16 {
    case synced = 0
    case needsCreate = 1
    case needsUpdate = 2
    case needsDelete = 3
}

// MARK: - Document CoreData extensions
extension DocumentEntity {
    // Convert to DocumentDTO for API operations
    func toDTO() -> DocumentDTO {
        return DocumentDTO(
            id: self.id ?? UUID().uuidString,
            name: self.name ?? "Untitled",
            isFavorite: self.isFavorite,
            createdAt: self.createdAt ?? Date(),
            updatedAt: self.updatedAt ?? Date()
        )
    }
    
    // Create a new DocumentEntity from a DocumentDTO
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
    
    // Update an existing DocumentEntity from a DocumentDTO
    func update(from dto: DocumentDTO) {
        self.name = dto.name
        self.isFavorite = dto.isFavorite
        self.updatedAt = dto.updatedAt
        self.syncStatus = DocumentSyncStatus.synced.rawValue
    }
    
    // Mark document as needing to be created on the server
    func markForCreation() {
        self.syncStatus = DocumentSyncStatus.needsCreate.rawValue
    }
    
    // Mark document as needing to be updated on the server
    func markForUpdate() {
        self.syncStatus = DocumentSyncStatus.needsUpdate.rawValue
    }
    
    // Mark document as needing to be deleted from the server
    func markForDeletion() {
        self.syncStatus = DocumentSyncStatus.needsDelete.rawValue
    }
}
