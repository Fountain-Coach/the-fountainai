#if canImport(SwiftUI) && canImport(Teatro) && canImport(TeatroRenderAPI)
import SwiftUI
import Teatro
import TeatroRenderAPI

/// Observable model powering the control plane dashboard.
public final class ControlPlaneUIModel: ObservableObject {
    /// Latest service statuses reported by the control plane.
    @Published public var statuses: [ServiceStatus] = []
    /// Accumulated log lines streamed from supervised services.
    @Published public var logs: [String] = []
    /// Optional Teatro SVG scene and timeline.
    @Published public var svg: Data = Data()
    @Published public var timeline: Data?

    private let supervisor: Supervisor
    private let services: [String: Service]

    public init(supervisor: Supervisor, services: [Service]) {
        self.supervisor = supervisor
        self.services = Dictionary(uniqueKeysWithValues: services.map { ($0.name, $0) })
    }

    /// Update the dashboard with freshly polled service statuses.
    @MainActor
    public func update(statuses: [ServiceStatus]) {
        self.statuses = statuses
    }

    /// Append a new log line to the dashboard's log view.
    @MainActor
    public func appendLog(_ line: String) {
        logs.append(line)
    }

    /// Toggle execution state of the given service.
    public func toggle(service name: String) {
        if supervisor.isRunning(serviceName: name) {
            supervisor.terminate(serviceName: name)
        } else if let svc = services[name] {
            try? supervisor.start(service: svc)
        }
    }

    /// Restart the specified service using the supervisor.
    public func restart(service name: String) {
        if let svc = services[name] {
            supervisor.restart(service: svc)
        }
    }
}
#endif
