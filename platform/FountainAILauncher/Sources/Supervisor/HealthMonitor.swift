import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Periodically probes service health endpoints and restarts failing services.
public final class HealthMonitor {
    private let supervisor: Supervisor
    private var timer: DispatchSourceTimer?
    private let interval: TimeInterval

    /// Creates a new health monitor.
    /// - Parameters:
    ///   - supervisor: Supervisor used for restarting services.
    ///   - interval: Time between health checks in seconds.
    public init(supervisor: Supervisor, interval: TimeInterval = 5) {
        self.supervisor = supervisor
        self.interval = interval
    }

    /// Begins monitoring the provided services.
    /// - Parameter services: Services to probe.
    public func startMonitoring(services: [Service]) {
        let queue = DispatchQueue(label: "health-monitor")
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler { [weak supervisor] in
            guard let supervisor = supervisor else { return }
            for service in services {
                guard service.shouldRestart, let port = service.port, let path = service.healthPath else { continue }
                let url = URL(string: "http://127.0.0.1:\(port)\(path)")!
                let task = URLSession.shared.dataTask(with: url) { _, response, error in
                    if error != nil || (response as? HTTPURLResponse)?.statusCode != 200 {
                        print("Health check failed for \(service.name)")
                        supervisor.restart(service: service)
                    }
                }
                task.resume()
            }
        }
        timer.resume()
        self.timer = timer
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
