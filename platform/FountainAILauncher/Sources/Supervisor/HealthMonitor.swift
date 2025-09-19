import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Minimal interface required for supervising services.
public protocol SupervisorProtocol: AnyObject, Sendable {
    func restart(service: Service)
}

extension Supervisor: SupervisorProtocol {}

/// Periodically probes service health endpoints and restarts failing services.
public final class HealthMonitor {
    private let supervisor: SupervisorProtocol
    private var timer: DispatchSourceTimer?
    private let interval: TimeInterval
    private let stateQueue = DispatchQueue(label: "health-monitor.state")
    private var failureReasons: [String: String] = [:]
    private var restartCounts: [String: Int] = [:]

    /// Creates a new health monitor.
    /// - Parameters:
    ///   - supervisor: Supervisor used for restarting services.
    ///   - interval: Time between health checks in seconds.
    public init(supervisor: SupervisorProtocol, interval: TimeInterval = 5) {
        self.supervisor = supervisor
        self.interval = interval
    }

    /// Begins monitoring the provided services.
    /// - Parameter services: Services to probe.
    public func startMonitoring(services: [Service]) {
        let queue = DispatchQueue(label: "health-monitor")
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + interval, repeating: interval)
        let watchable = services.compactMap { service -> (Service, Int, String)? in
            guard let port = service.port, let path = service.healthPath else { return nil }
            return (service, port, path)
        }
        if watchable.isEmpty {
            print("Health monitor ready: no services expose HTTP health checks.")
        } else {
            let summary = watchable.map { "\($0.0.name)@\($0.1)\($0.2)" }.joined(separator: ", ")
            print("Health monitor watching \(watchable.count) services: \(summary)")
        }
        timer.setEventHandler { [weak self, weak supervisor] in
            guard let self = self, let supervisor = supervisor else { return }
            for service in services {
                guard service.shouldRestart, let port = service.port, let path = service.healthPath else { continue }
                let url = URL(string: "http://127.0.0.1:\(port)\(path)")!
                let task = URLSession.shared.dataTask(with: url) { _, response, error in
                    if let detail = Self.evaluate(response: response, error: error) {
                        self.recordFailure(for: service.name, detail: detail)
                        print("Health check failed for \(service.name): \(detail)")
                        supervisor.restart(service: service)
                    } else {
                        self.clearFailure(for: service.name)
                    }
                }
                task.resume()
            }
        }
        timer.resume()
        self.timer = timer
    }

    public func currentIssues() -> [String: String] {
        stateQueue.sync { failureReasons }
    }

    public static func initialCheck(services: [Service], timeout: TimeInterval = 3) -> [HealthCheckResult] {
        let session = URLSession(configuration: .default)
        var results: [HealthCheckResult] = []
        for service in services {
            guard let port = service.port, let path = service.healthPath else {
                results.append(HealthCheckResult(service: service, healthy: false, detail: "no health endpoint"))
                continue
            }
            let url = URL(string: "http://127.0.0.1:\(port)\(path)")!
            let resultQueue = DispatchQueue(label: "health-check.detail")
            var detail: String?
            let semaphore = DispatchSemaphore(value: 0)
            let task = session.dataTask(with: url) { _, response, error in
                let computed = Self.evaluate(response: response, error: error)
                resultQueue.sync { detail = computed }
                semaphore.signal()
            }
            task.resume()
            _ = semaphore.wait(timeout: .now() + timeout)
            let snapshot = resultQueue.sync { detail }
            if let snapshot {
                results.append(HealthCheckResult(service: service, healthy: false, detail: snapshot))
            } else {
                results.append(HealthCheckResult(service: service, healthy: true, detail: nil))
            }
        }
        session.invalidateAndCancel()
        return results
    }

    private static func evaluate(response: URLResponse?, error: Error?) -> String? {
        if let error {
            return error.localizedDescription
        }
        guard let http = response as? HTTPURLResponse else {
            return "no response"
        }
        guard (200..<300).contains(http.statusCode) else {
            return "HTTP \(http.statusCode)"
        }
        return nil
    }

    private func recordFailure(for service: String, detail: String) {
        stateQueue.async { [weak self] in
            guard let self = self else { return }
            self.failureReasons[service] = detail
            let count = (self.restartCounts[service] ?? 0) + 1
            self.restartCounts[service] = count
        }
    }

    private func clearFailure(for service: String) {
        stateQueue.async { [weak self] in
            guard let self = self else { return }
            self.failureReasons.removeValue(forKey: service)
            self.restartCounts.removeValue(forKey: service)
        }
    }

    public struct HealthCheckResult {
        public let service: Service
        public let healthy: Bool
        public let detail: String?
    }
}

extension HealthMonitor: @unchecked Sendable {}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
