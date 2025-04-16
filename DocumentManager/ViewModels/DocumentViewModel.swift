import Foundation
import Combine

/**
 * Document View Model
 *
 * Represents a single document for display in the UI.
 * Provides properties and methods for interacting with a document.
 */
class DocumentViewModel: ObservableObject, Identifiable {
    /// Unique identifier for the document
    let id: String?
    
    /// Title of the document
    @Published var title: String
    
    /// Content of the document
    @Published var content: String
    
    /// Creation date of the document
    let createdAt: Date
    
    /// Last update date of the document
    @Published var updatedAt: Date
    
    /// Whether the document is marked as a favorite
    @Published var isFavorite: Bool
    
    /// Type of the document file (e.g., pdf, txt, doc)
    let fileType: String
    
    /// Size of the document in bytes
    @Published var size: Int64
    
    /// Array of tags associated with the document
    @Published var tags: [String]
    
    /// The sync status of the document (0=synced, 1=needsUpload, 2=needsUpdate, 3=needsDelete)
    @Published var syncStatus: Int16
    
    /// Whether the document is currently syncing
    @Published var isSyncing: Bool = false
    
    /// The Core Data entity this view model represents
    private let document: Document
    
    /**
     * Initialize from a Core Data Document entity
     *
     * Creates a view model that represents a Document entity from Core Data.
     *
     * - Parameter document: The Core Data Document entity to represent
     */
    init(document: Document) {
        self.document = document
        
        self.id = document.id
        self.title = document.title ?? "Untitled"
        self.content = document.content ?? ""
        self.createdAt = document.createdAt ?? Date()
        self.updatedAt = document.updatedAt ?? Date()
        self.isFavorite = document.isFavorite
        self.fileType = document.fileType ?? "txt"
        self.size = document.size
        self.tags = document.tags ?? []
        self.syncStatus = document.syncStatus
    }
    
    /**
     * Update the underlying Document entity with current view model values
     *
     * Synchronizes changes from the view model back to the Core Data entity.
     */
    func updateDocument() {
        document.title = title
        document.content = content
        document.updatedAt = Date()
        document.isFavorite = isFavorite
        document.size = size
        document.tags = tags
        
        // If already marked for upload, keep that status
        if document.syncStatus != 1 {
            document.syncStatus = 2 // Needs Update
        }
        
        do {
            try CoreDataStack.shared.saveContext(document.managedObjectContext!)
        } catch {
            print("Error updating document entity: \(error)")
        }
    }
    
    /**
     * Get a formatted string representation of the document size
     *
     * Converts the size in bytes to a human-readable format.
     *
     * - Returns: A formatted string like "1.2 MB" or "450 KB"
     */
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    /**
     * Get a formatted string representation of the last update date
     *
     * Formats the date to a readable string like "June 15, 2025".
     *
     * - Returns: A formatted date string
     */
    var formattedUpdateDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: updatedAt)
    }
    
    /**
     * Get an icon name for the document based on its file type
     *
     * Maps common file types to SF Symbol icon names.
     *
     * - Returns: An SF Symbol icon name
     */
    var iconName: String {
        switch fileType.lowercased() {
        case "pdf":
            return "doc.text.fill"
        case "doc", "docx":
            return "doc.fill"
        case "xls", "xlsx":
            return "tablecells.fill"
        case "ppt", "pptx":
            return "chart.bar.fill"
        case "jpg", "jpeg", "png", "gif", "heic":
            return "photo.fill"
        case "mp3", "wav", "aac":
            return "music.note"
        case "mp4", "mov", "avi":
            return "film.fill"
        case "zip", "rar", "tar", "gz":
            return "archivebox.fill"
        default:
            return "doc.text"
        }
    }
    
    /**
     * Get a display-friendly file type name
     *
     * Converts file extensions to user-friendly names.
     *
     * - Returns: A user-friendly file type description
     */
    var fileTypeDisplayName: String {
        switch fileType.lowercased() {
        case "pdf":
            return "PDF Document"
        case "doc", "docx":
            return "Word Document"
        case "xls", "xlsx":
            return "Excel Spreadsheet"
        case "ppt", "pptx":
            return "PowerPoint Presentation"
        case "txt":
            return "Text File"
        case "jpg", "jpeg", "png", "gif", "heic":
            return "Image"
        case "mp3", "wav", "aac":
            return "Audio File"
        case "mp4", "mov", "avi":
            return "Video File"
        case "zip", "rar", "tar", "gz":
            return "Archive"
        default:
            return fileType.uppercased()
        }
    }
    
    /**
     * Get the sync status as a text description
     *
     * Converts the numeric sync status to a user-friendly string.
     *
     * - Returns: A description of the sync status
     */
    var syncStatusText: String {
        switch syncStatus {
        case 0:
            return "Synced"
        case 1:
            return "Pending Upload"
        case 2:
            return "Pending Update"
        case 3:
            return "Pending Deletion"
        default:
            return "Unknown"
        }
    }
    
    /**
     * Get a color representing the sync status
     *
     * Maps sync statuses to color names for UI display.
     *
     * - Returns: A color name
     */
    var syncStatusColor: String {
        switch syncStatus {
        case 0:
            return "green"
        case 1, 2, 3:
            return "orange"
        default:
            return "gray"
        }
    }
}