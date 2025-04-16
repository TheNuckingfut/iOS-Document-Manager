import UIKit
import SwiftUI

/**
 * Scene Delegate
 *
 * Manages scene-based lifecycle events and configures the root view hierarchy.
 * Responsible for setting up the main UI for each scene.
 */
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    /// The window that will hold our view hierarchy
    var window: UIWindow?
    
    /**
     * Called when a new scene is being created
     *
     * Sets up the root view controller with our SwiftUI view hierarchy.
     */
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Create the SwiftUI view that provides the window contents
        let documentListViewModel = DocumentListViewModel()
        let contentView = MainTabView(viewModel: documentListViewModel)
        
        // Use a UIHostingController as window root view controller
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    /**
     * Called when the scene has moved to the foreground
     *
     * Updates the app's data when the scene becomes active.
     */
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Can be used to refresh data when the scene becomes active
    }
    
    /**
     * Called when the scene is about to move to the background
     *
     * Performs cleanup and data saving when the scene is no longer active.
     */
    func sceneWillResignActive(_ scene: UIScene) {
        // Can be used to pause ongoing tasks or save data when scene is about to resign active
    }
    
    /**
     * Called when the scene has entered the background
     */
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save changes to Core Data when the scene enters the background
        CoreDataStack.shared.saveContext()
    }
}