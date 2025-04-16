import UIKit
import CoreData

/**
 * App Delegate
 *
 * Manages application lifecycle events and coordinates the app's core services.
 * Initializes the Core Data stack and sets up the initial UI.
 */
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    /**
     * Application launch lifecycle method
     *
     * Initializes core services and configures third-party integrations.
     * Also sets up the appearance for the UINavigationBar.
     */
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Setup navigation bar appearance for the whole app
        configureNavigationBarAppearance()
        
        // Start network monitoring
        NetworkMonitor.shared.startMonitoring()
        
        return true
    }
    
    /**
     * Configure global navigation bar appearance
     *
     * Sets up a consistent look and feel for navigation bars across the app.
     */
    private func configureNavigationBarAppearance() {
        // Create standard appearance object
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // Apply to standard, compact, and scrollEdge appearances
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    // MARK: - UISceneSession Lifecycle
    
    /**
     * Creates the scene configuration for a new scene session
     */
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    /**
     * Called when a scene session is being discarded
     */
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Can be used to release resources when scenes are discarded
    }
    
    /**
     * Clean up on application termination
     */
    func applicationWillTerminate(_ application: UIApplication) {
        // Save changes in the Core Data context
        CoreDataStack.shared.saveContext()
        
        // Stop network monitoring
        NetworkMonitor.shared.stopMonitoring()
    }
}