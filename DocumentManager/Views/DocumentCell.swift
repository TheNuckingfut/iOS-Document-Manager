import SwiftUI
import CoreData

struct DocumentCell: View {
    let document: DocumentEntity
    @Environment(\.colorScheme) var colorScheme
    
    private var documentViewModel: DocumentViewModel {
        DocumentViewModel(document: document)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name ?? "Untitled Document")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if documentViewModel.needsSync {
                        Text("• \(documentViewModel.statusText)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            if document.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        if let date = document.updatedAt {
            return formatter.string(from: date)
        } else {
            return "Unknown date"
        }
    }
}
