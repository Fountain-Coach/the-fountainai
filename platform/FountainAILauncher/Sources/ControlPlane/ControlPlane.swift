import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Simple HTTP control plane exposing supervisor management endpoints.
public final class ControlPlane: @unchecked Sendable {
    private let supervisor: Supervisor
    private let services: [String: Service]
    private var server: NIOHTTPServer?
    private var port: Int = 0

    /// Creates a new control plane managing the given services.
    /// - Parameters:
    ///   - supervisor: Supervisor responsible for service processes.
    ///   - services: Known services keyed by name.
    public init(supervisor: Supervisor, services: [Service]) {
        self.supervisor = supervisor
        self.services = Dictionary(uniqueKeysWithValues: services.map { ($0.name, $0) })
    }

    /// Starts the HTTP server on the provided port.
    /// - Parameter port: Desired listening port. Use 0 for an ephemeral port.
    /// - Returns: The actual port the server bound to.
    @discardableResult
    public func start(port: Int) async throws -> Int {
        let kernel = makeKernel()
        let server = NIOHTTPServer(kernel: kernel)
        let actual = try await server.start(port: port)
        self.server = server
        self.port = actual
        return actual
    }

    /// Stops the HTTP server if running.
    public func stop() async throws {
        try await server?.stop()
    }

    /// Returns the port the server is listening on.
    public var listenPort: Int { port }

    private func makeKernel() -> HTTPKernel {
        HTTPKernel { [weak self] req in
            guard let self else { return HTTPResponse(status: 500) }
            switch (req.method, req.path) {
            case ("GET", "/status"):
                return try await self.statusHandler()
            case ("POST", "/shutdown"):
                Task.detached { [supervisor] in
                    supervisor.terminateAll()
                    exit(0)
                }
                return HTTPResponse(status: 200)
            case ("POST", let path) where path.hasPrefix("/restart/"):
                let name = String(path.dropFirst("/restart/".count))
                guard let service = self.services[name] else {
                    return HTTPResponse(status: 404)
                }
                self.supervisor.restart(service: service)
                return HTTPResponse(status: 200)
            default:
                return HTTPResponse(status: 404)
            }
        }
    }

    private func statusHandler() async throws -> HTTPResponse {
        var statuses: [ServiceStatus] = []
        for (name, service) in services {
            let running = supervisor.isRunning(serviceName: name)
            var healthy = running
            if running, let port = service.port, let path = service.healthPath {
                let url = URL(string: "http://127.0.0.1:\(port)\(path)")!
                do {
                    let (_, response) = try await URLSession.shared.data(from: url)
                    healthy = (response as? HTTPURLResponse)?.statusCode == 200
                } catch {
                    healthy = false
                }
            }
            statuses.append(ServiceStatus(name: name, running: running, healthy: healthy))
        }
        let data = try JSONEncoder().encode(statuses)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
}

/// Status information returned by the control plane.
public struct ServiceStatus: Codable, Sendable {
    /// Service name.
    public let name: String
    /// Whether the process is running.
    public let running: Bool
    /// Whether the last health probe succeeded.
    public let healthy: Bool
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
