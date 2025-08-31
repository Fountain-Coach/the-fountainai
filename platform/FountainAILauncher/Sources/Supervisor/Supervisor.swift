import Foundation

/// Manages child service processes and keeps them alive.
public final class Supervisor: @unchecked Sendable {
    /// Running child processes keyed by service name.
    private var processes: [String: Process] = [:]
    /// Service descriptors for restart logic.
    private var serviceConfigs: [String: Service] = [:]
    /// Directory where logs will be written.
    private let logDirectory: URL

    /// Creates a new supervisor writing logs to the given directory.
    /// - Parameter logDirectory: Directory where service logs are stored.
    public init(logDirectory: URL = URL(fileURLWithPath: "logs", isDirectory: true)) {
        self.logDirectory = logDirectory
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
    }

    @discardableResult
    /// Launches a single service process.
    /// - Parameter service: Descriptor for the binary to execute.
    /// - Returns: The running `Process` instance.
    public func start(service: Service) throws -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: service.binaryPath)
        process.arguments = service.arguments

        let sanitizedName = service.name.replacingOccurrences(of: " ", with: "_")
        let logURL = logDirectory.appendingPathComponent("\(sanitizedName).log")
        if !FileManager.default.fileExists(atPath: logURL.path) {
            FileManager.default.createFile(atPath: logURL.path, contents: nil)
        }
        let logHandle = try FileHandle(forWritingTo: logURL)
        logHandle.seekToEndOfFile()
        process.standardOutput = logHandle
        process.standardError = logHandle

        try process.run()
        processes[service.name] = process
        serviceConfigs[service.name] = service
        print("Started \(service.name) (pid: \(process.processIdentifier))")
        return process
    }

    /// Starts a collection of services sequentially.
    /// - Parameter services: Array of ``Service`` descriptors.
    public func start(services: [Service]) throws {
        for service in services {
            try start(service: service)
        }
    }

    /// Attempts to restart the given service.
    /// - Parameter service: Descriptor to restart.
    public func restart(service: Service) {
        terminate(serviceName: service.name)
        try? start(service: service)
    }

    /// Terminates a single service by name.
    /// - Parameter serviceName: Name of the service to terminate.
    public func terminate(serviceName: String) {
        if let process = processes[serviceName], process.isRunning {
            process.terminate()
        }
        processes[serviceName] = nil
        serviceConfigs[serviceName] = nil
    }

    /// Terminates all running services and clears internal state.
    public func terminateAll() {
        for (name, _) in processes {
            terminate(serviceName: name)
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
