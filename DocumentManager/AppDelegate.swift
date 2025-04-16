import UIKit
import CoreData

/**
 * Application Delegate
 *
 * The main entry point for the application's lifecycle events. This class is responsible for:
 * - Setting up essential services at app launch
 * - Managing scene configurations
 * - Handling app termination and cleanup
 *
 * The AppDelegate works with the SceneDelegate to manage the app's lifecycle,
 * with AppDelegate handling app-wide events and SceneDelegate handling UI-specific events.
 */
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    /**
     * Called when the application has finished launching
     *
     * This method initializes key application services that need to run for the entire
     * lifecycle of the app, such as the network connectivity monitor.
     *
     * - Parameters:
     *   - application: The singleton app object
     *   - launchOptions: A dictionary indicating the reason the app was launched
     * - Returns: True to allow the app to proceed with launching
     */
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Start monitoring network connectivity
        NetworkMonitor.shared.startMonitoring()
        return true
    }

    // MARK: UISceneSession Lifecycle
    
    /**
     * Configures a new UISceneSession
     *
     * Called when a new scene session is being created, allowing the app to
     * configure the session before it's connected to a scene object.
     *
     * - Parameters:
     *   - application: The singleton app object
     *   - connectingSceneSession: The new scene session
     *   - options: Options for connecting the scene
     * - Returns: The configuration to use for the scene
     */
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    /**
     * Called when the user discards scene sessions
     *
     * This method can be used to release any resources associated with
     * the discarded scenes, as they will not be returned to the app.
     *
     * - Parameters:
     *   - application: The singleton app object
     *   - sceneSessions: The set of scene sessions that were discarded
     */
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Handle cleanup for discarded scene sessions if needed
    }
    
    /**
     * Called when the application is about to terminate
     *
     * This is the last chance to perform cleanup operations such as saving data
     * and shutting down services. The app is terminated shortly after this method returns.
     *
     * - Parameter application: The singleton app object
     */
    func applicationWillTerminate(_ application: UIApplication) {
        // Save any pending changes to Core Data
        CoreDataStack.shared.saveContext()
        
        // Stop the network monitoring service
        NetworkMonitor.shared.stopMonitoring()
    }
}
