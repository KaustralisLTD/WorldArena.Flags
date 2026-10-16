import Network
import Combine

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    
    private init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
} 