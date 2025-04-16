import Foundation

// MARK: - Document Models
struct Document {
    let id: String
    var name: String
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
}

enum DocumentSyncStatus {
    case synced
    case needsCreate
    case needsUpdate
    case needsDelete
}

// MARK: - Simulated Services
class NetworkService {
    static let shared = NetworkService()
    
    var isOnline: Bool {
        return Bool.random()
    }
    
    func fetchDocuments() -> [Document] {
        print("Fetching documents from server...")
        return sampleDocuments
    }
    
    func createDocument(_ document: Document) {
        print("Creating document on server: \(document.name)")
    }
    
    func updateDocument(_ document: Document) {
        print("Updating document on server: \(document.name)")
    }
    
    func deleteDocument(id: String) {
        print("Deleting document from server with ID: \(id)")
    }
    
    private var sampleDocuments: [Document] {
        return [
            Document(id: "1", name: "Business Plan.docx", isFavorite: true, createdAt: Date(), updatedAt: Date()),
            Document(id: "2", name: "Meeting Notes.txt", isFavorite: false, createdAt: Date(), updatedAt: Date()),
            Document(id: "3", name: "Project Timeline.pdf", isFavorite: true, createdAt: Date(), updatedAt: Date()),
            Document(id: "4", name: "Budget Forecast.xlsx", isFavorite: false, createdAt: Date(), updatedAt: Date())
        ]
    }
}

// MARK: - Main Application Simulation
print("DocumentManager iOS App Simulator")
print("================================")
print("This is a simulation of the Document Manager app.")
print("In a real iOS environment, this would launch the full application.")
print("--------------------------------")
print("App Structure Overview:")
print("- MVVM Architecture")
print("- Core Data for persistence")
print("- Online/Offline synchronization")
print("- Document CRUD operations")

let networkService = NetworkService.shared
let isOnline = networkService.isOnline

print("\nNetwork Status: \(isOnline ? "Online" : "Offline")")

if isOnline {
    let documents = networkService.fetchDocuments()
    
    print("\nAvailable Documents:")
    for (index, doc) in documents.enumerated() {
        print("\(index + 1). \(doc.name) \(doc.isFavorite ? "(Favorite)" : "")")
    }
    
    print("\nSimulating document operations:")
    // Create a new document
    let newDoc = Document(id: "5", name: "New Proposal.docx", isFavorite: false, createdAt: Date(), updatedAt: Date())
    networkService.createDocument(newDoc)
    
    // Update an existing document
    var updatedDoc = networkService.fetchDocuments()[0]
    updatedDoc.name = "Updated Business Plan.docx"
    networkService.updateDocument(updatedDoc)
    
    // Delete a document
    networkService.deleteDocument(id: "2")
    
    print("\nSyncing documents with server...")
    print("All documents synchronized successfully!")
} else {
    print("Working in offline mode. Changes will sync when connectivity is restored.")
    print("Documents are stored locally in Core Data.")
    
    // Simulate offline operations that will be synced later
    print("\nOffline Operations Queue:")
    print("- Create: New Meeting Agenda.txt")
    print("- Update: Project Timeline.pdf")
    print("- Delete: Archived Report.docx")
    print("\nThese operations will be performed when online.")
}

print("\nThank you for using Document Manager!")