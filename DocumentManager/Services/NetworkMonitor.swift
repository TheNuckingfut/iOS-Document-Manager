import Foundation
import Network
import Combine

/**
 * Network Monitor
 *
 * A service that monitors the device's network connectivity status
 * and notifies the app when changes occur. Implemented as a singleton
 * to ensure consistent monitoring across the app.
 *
 * Conforms to ObservableObject to integrate with SwiftUI and allow
 * views to reactively update based on connectivity changes.
 */
class NetworkMonitor: ObservableObject {
    /// Shared singleton instance of the NetworkMonitor
    static let shared = NetworkMonitor()
    
    /// The NWPathMonitor instance that does the actual network monitoring
    private let monitor: NWPathMonitor
    
    /// A dedicated dispatch queue for network monitoring operations
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    /**
     * Published property that indicates whether the device has an active network connection
     * Views can observe this property to update their UI based on connectivity status
     */
    @Published var isConnected = false
    
    /**
     * Private initializer to enforce singleton pattern
     * Initializes the NWPathMonitor and starts monitoring immediately
     */
    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    /**
     * Starts monitoring network connectivity changes
     *
     * When connectivity is restored, this triggers a sync operation
     * to upload any pending changes made while offline
     */
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                if self?.isConnected == true {
                    // Attempt to sync pending changes when network becomes available
                    SyncService.shared.syncPendingChanges()
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    /**
     * Stops network monitoring
     *
     * Should be called when the app is terminating or when
     * network monitoring is no longer needed
     */
    func stopMonitoring() {
        monitor.cancel()
    }
}
