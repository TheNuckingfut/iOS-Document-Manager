import SwiftUI

struct MainTabView: View {
    @ObservedObject var viewModel: DocumentListViewModel
    @Environment(\.colorScheme) var colorScheme
    
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
            // Set the appearance of TabBar
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Initial data load
            viewModel.loadDocumentsFromCoreData()
        }
        .sheet(isPresented: $viewModel.isCreatingDocument) {
            CreateDocumentView(viewModel: viewModel)
        }
        .refreshable {
            viewModel.fetchDocumentsFromServer()
        }
    }
}
