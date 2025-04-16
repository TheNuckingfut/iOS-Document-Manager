import SwiftUI

/**
 * Main Tab View
 *
 * The root container view for the application, implementing a tabbed interface
 * with Home (all documents) and Favorites tabs. This view manages:
 * - Navigation between primary app sections
 * - Document list presentation for both all documents and favorites
 * - Global UI configuration for tabs
 * - Initial data loading and refresh functionality
 * - Document creation via modal sheet
 */
struct MainTabView: View {
    /// View model providing document data and operations
    @ObservedObject var viewModel: DocumentListViewModel
    
    /// Current color scheme (light/dark mode) from the environment
    @Environment(\.colorScheme) var colorScheme
    
    /// Main view body implementing the tabbed interface
    var body: some View {
        TabView {
            // Home Tab - All Documents
            NavigationView {
                DocumentListView(
                    documents: viewModel.documents,
                    viewModel: viewModel,
                    title: "All Documents"
                )
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            // Favorites Tab
            NavigationView {
                DocumentListView(
                    documents: viewModel.favoriteDocuments,
                    viewModel: viewModel,
                    title: "Favorites",
                    showEmptyFavorites: true
                )
            }
            .tabItem {
                Label("Favorites", systemImage: "star.fill")
            }
        }
        .accentColor(colorScheme == .dark ? .white : .blue)
        .onAppear {
            // Set the appearance of TabBar for consistent styling
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Initial data load when view appears
            viewModel.loadDocumentsFromCoreData()
        }
        .sheet(isPresented: $viewModel.isCreatingDocument) {
            // Present document creation sheet when isCreatingDocument is true
            CreateDocumentView(viewModel: viewModel)
        }
        .refreshable {
            // Pull-to-refresh functionality to fetch server updates
            viewModel.fetchDocumentsFromServer()
        }
    }
}
