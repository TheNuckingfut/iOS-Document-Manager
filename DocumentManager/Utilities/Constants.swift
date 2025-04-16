import Foundation
import UIKit
import SwiftUI

enum Constants {
    // API Constants
    static let baseURL = "https://67ff5bb258f18d7209f0debe.mockapi.io"
    static let documentsEndpoint = "/documents"
    
    // UI Constants
    struct UI {
        static let cornerRadius: CGFloat = 10
        static let standardPadding: CGFloat = 16
        static let buttonHeight: CGFloat = 50
        static let bottomSheetHeight: CGFloat = UIScreen.main.bounds.height * 0.7
        
        struct Colors {
            static let primaryColor = Color.blue
            static let secondaryColor = Color.gray
            static let accentColor = Color.orange
            
            static let darkBackground = Color(UIColor.systemBackground)
            static let darkSecondaryBackground = Color(UIColor.secondarySystemBackground)
            
            static let lightBackground = Color.white
            static let lightSecondaryBackground = Color(UIColor.systemGray6)
        }
    }
    
    // Animation Constants
    struct Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
    }
    
    // Core Data Constants
    struct CoreData {
        static let modelName = "DocumentManager"
        static let documentEntityName = "DocumentEntity"
    }
}
