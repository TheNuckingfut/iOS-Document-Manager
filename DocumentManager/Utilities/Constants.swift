import Foundation
import UIKit
import SwiftUI

/**
 * Application Constants
 *
 * This enum serves as a centralized place for all the constants used throughout the application.
 * Organizing constants this way improves maintainability by making it easy to update values
 * in a single location rather than scattered throughout the codebase.
 */
enum Constants {
    // MARK: - API Constants
    
    /// Base URL for all API endpoints
    static let baseURL = "https://67ff5bb258f18d7209f0debe.mockapi.io"
    
    /// Endpoint for document operations
    static let documentsEndpoint = "/documents"
    
    // MARK: - UI Constants
    
    /**
     * UI-related constants
     *
     * This struct contains constants for UI elements like sizing, spacing,
     * and dimensions to maintain visual consistency across the app.
     */
    struct UI {
        /// Standard corner radius for UI elements
        static let cornerRadius: CGFloat = 10
        
        /// Standard padding for content areas
        static let standardPadding: CGFloat = 16
        
        /// Standard height for buttons
        static let buttonHeight: CGFloat = 50
        
        /// Height for bottom sheets (70% of screen height)
        static let bottomSheetHeight: CGFloat = UIScreen.main.bounds.height * 0.7
        
        /**
         * Color constants
         *
         * This nested struct provides a consistent color palette for the app,
         * supporting both light and dark modes.
         */
        struct Colors {
            /// Primary brand color
            static let primaryColor = Color.blue
            
            /// Secondary brand color for less emphasis
            static let secondaryColor = Color.gray
            
            /// Accent color for highlights and calls to action
            static let accentColor = Color.orange
            
            /// Main background color for dark mode
            static let darkBackground = Color(UIColor.systemBackground)
            
            /// Secondary background color for dark mode
            static let darkSecondaryBackground = Color(UIColor.secondarySystemBackground)
            
            /// Main background color for light mode
            static let lightBackground = Color.white
            
            /// Secondary background color for light mode
            static let lightSecondaryBackground = Color(UIColor.systemGray6)
        }
    }
    
    // MARK: - Animation Constants
    
    /**
     * Animation constants
     *
     * This struct provides standardized animation settings to maintain
     * consistent motion and timing throughout the app.
     */
    struct Animation {
        /// Standard easing animation for most UI transitions
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        
        /// Spring animation for more natural, bouncy transitions
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
    }
    
    // MARK: - Core Data Constants
    
    /**
     * Core Data constants
     *
     * This struct contains constants related to the Core Data persistence layer,
     * including model and entity names.
     */
    struct CoreData {
        /// Name of the Core Data model
        static let modelName = "DocumentManager"
        
        /// Name of the document entity in Core Data
        static let documentEntityName = "DocumentEntity"
    }
}
