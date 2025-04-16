import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Initialize view models and services
        let documentListViewModel = DocumentListViewModel()
        
        // Create the SwiftUI view that provides the window contents
        let mainTabView = MainTabView(viewModel: documentListViewModel)
        
        // Use a UIHostingController as window root view controller.
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: mainTabView)
        self.window = window
        window.makeKeyAndVisible()
        
        // Fetch documents when the app starts
        documentListViewModel.fetchDocumentsFromServer()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Save Core Data changes when scene disconnects
        CoreDataStack.shared.saveContext()
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Sync pending offline changes when app becomes active
        SyncService.shared.syncPendingChanges()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Save any pending changes to Core Data
        CoreDataStack.shared.saveContext()
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save changes in the application's managed object context when the scene enters background
        CoreDataStack.shared.saveContext()
    }
}
