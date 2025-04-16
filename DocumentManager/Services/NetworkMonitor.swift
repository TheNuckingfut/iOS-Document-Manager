import Foundation
import Network

/**
 * Network Monitor
 *
 * Monitors the device's network connectivity status.
 * Publishes network status changes that can be observed by other components.
 */
class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    /// The current network status (connected or disconnected)
    private(set) var isConnected: Bool = false
    
    /// The connection type (wifi, cellular, etc.)
    private(set) var connectionType: ConnectionType = .unknown
    
    /// Observers that will be notified of network status changes
    private var observers = [NetworkStatusObserver]()
    
    private init() {
        monitor = NWPathMonitor()
    }
    
    /**
     * Start monitoring network status changes
     *
     * Begins tracking changes to network connectivity and updates status properties.
     */
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            self.isConnected = path.status == .satisfied
            self.connectionType = self.getConnectionType(path)
            
            // Notify observers on the main thread
            DispatchQueue.main.async {
                self.notifyObservers()
            }
        }
        
        monitor.start(queue: queue)
    }
    
    /**
     * Stop monitoring network status changes
     */
    func stopMonitoring() {
        monitor.cancel()
    }
    
    /**
     * Add observer for network status changes
     *
     * Registers an object to receive notifications when network status changes.
     *
     * - Parameter observer: The object to register as an observer
     */
    func addObserver(_ observer: NetworkStatusObserver) {
        observers.append(observer)
    }
    
    /**
     * Remove observer for network status changes
     *
     * Unregisters an object from receiving notifications.
     *
     * - Parameter observer: The object to unregister
     */
    func removeObserver(_ observer: NetworkStatusObserver) {
        observers.removeAll { $0 === observer }
    }
    
    /**
     * Notify all registered observers of network status changes
     */
    private func notifyObservers() {
        for observer in observers {
            observer.networkStatusDidChange(isConnected: isConnected, connectionType: connectionType)
        }
    }
    
    /**
     * Determine the connection type from a network path
     *
     * - Parameter path: The network path to analyze
     * - Returns: The type of connection (wifi, cellular, etc.)
     */
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
    
    /**
     * Connection type enumeration
     *
     * Represents the various types of network connections.
     */
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
}

/**
 * Network Status Observer Protocol
 *
 * Protocol for objects that want to observe network status changes.
 */
protocol NetworkStatusObserver: AnyObject {
    /**
     * Called when network status changes
     *
     * - Parameters:
     *   - isConnected: Whether the device has internet connectivity
     *   - connectionType: The type of network connection
     */
    func networkStatusDidChange(isConnected: Bool, connectionType: NetworkMonitor.ConnectionType)
}