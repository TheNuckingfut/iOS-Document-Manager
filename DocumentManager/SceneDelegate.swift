import UIKit
import SwiftUI

/**
 * Scene Delegate
 *
 * Responsible for configuring and managing the UI scene lifecycle. This class handles:
 * - Setting up the initial UI hierarchy
 * - Managing scene state transitions (foreground, background, active, inactive)
 * - Coordinating data persistence during state changes
 *
 * In iOS 13+, SceneDelegate works alongside AppDelegate to manage the app:
 * AppDelegate handles app-wide concerns, while SceneDelegate handles UI scene-specific concerns.
 */
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    /// The window associated with this scene
    var window: UIWindow?
    
    /**
     * Called when a scene is being created and connected to the app
     *
     * This method sets up the initial UI hierarchy, configures the root view,
     * and initializes key view models and services needed for the scene.
     *
     * - Parameters:
     *   - scene: The scene that is being configured
     *   - session: The session containing configuration details for the scene
     *   - connectionOptions: Options for configuring the scene connection
     */
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
    
    /**
     * Called when the scene is being released by the system
     *
     * This happens when a user closes a scene or when the system decides
     * to reclaim the scene's resources. This is a good time to save any
     * unsaved data.
     *
     * - Parameter scene: The scene that is being released
     */
    func sceneDidDisconnect(_ scene: UIScene) {
        // Save Core Data changes when scene disconnects
        CoreDataStack.shared.saveContext()
    }
    
    /**
     * Called when the scene becomes active and interactive
     *
     * This is a good time to refresh data and perform tasks that
     * require user interaction, such as syncing pending changes.
     *
     * - Parameter scene: The scene that has become active
     */
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Sync pending offline changes when app becomes active
        SyncService.shared.syncPendingChanges()
    }
    
    /**
     * Called when the scene is about to stop being active and interactive
     *
     * This is a good time to save data and pause ongoing tasks.
     *
     * - Parameter scene: The scene that will resign active status
     */
    func sceneWillResignActive(_ scene: UIScene) {
        // Save any pending changes to Core Data
        CoreDataStack.shared.saveContext()
    }
    
    /**
     * Called when the scene is about to enter the foreground
     *
     * This is called as the scene transitions from the background to
     * the foreground, but before it becomes active.
     *
     * - Parameter scene: The scene that will enter the foreground
     */
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Prepare UI for foreground presentation if needed
    }
    
    /**
     * Called when the scene enters the background
     *
     * This is a good time to save data and release shared resources.
     * The app may be terminated at any point after this call.
     *
     * - Parameter scene: The scene that has entered the background
     */
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save changes in the application's managed object context when the scene enters background
        CoreDataStack.shared.saveContext()
    }
}
