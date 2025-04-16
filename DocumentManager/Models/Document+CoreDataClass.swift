import Foundation
import CoreData

/**
 * Document Entity
 *
 * Core Data entity representing a document in the application.
 * Contains properties for tracking document data, metadata, and sync status.
 */
@objc(Document)
public class Document: NSManagedObject {
    /**
     * Convert a Document entity to a JSON dictionary
     *
     * Used when sending document data to the server.
     *
     * - Returns: A dictionary representation of the document
     */
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id ?? UUID().uuidString,
            "title": title ?? "",
            "content": content ?? "",
            "createdAt": createdAt ?? Date(),
            "updatedAt": updatedAt ?? Date(),
            "fileType": fileType ?? "",
            "size": size
        ]
        
        if let tags = tags {
            dict["tags"] = tags
        }
        
        return dict
    }
}