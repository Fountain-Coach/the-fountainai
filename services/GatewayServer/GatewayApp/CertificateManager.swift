import Foundation

/// Manages periodic execution of a certificate renewal script.
public final class CertificateManager {
    /// Dispatch timer scheduling periodic renewals.
    private var timer: DispatchSourceTimer?
    /// Absolute path to the renewal script executed.
    private let scriptPath: String
    /// Delay between script executions.
    private let interval: TimeInterval

    /// Creates a new manager with optional script path and repeat interval.
    /// - Parameters:
    ///   - scriptPath: Shell script used for renewal.
    ///   - interval: Time between renewals in seconds.
    public init(scriptPath: String = "./scripts/renew-certs.sh", interval: TimeInterval = 86_400) {
        self.scriptPath = scriptPath
        self.interval = interval
    }

    /// Starts automatic certificate renewal on a timer.
    /// Invokes the configured shell script every ``interval`` seconds on a
    /// background queue until ``stop()`` is called.
    public func start() {
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler { [scriptPath] in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: scriptPath)
            do {
                try task.run()
            } catch {
                print("Certificate renewal failed: \(error)")
            }
        }
        self.timer = timer
        timer.resume()
    }

    /// Stops the timer and cancels future renewals.
    /// Safe to call multiple times; subsequent calls have no effect.
    public func stop() {
        timer?.cancel()
        timer = nil
    }

    /// Immediately runs the renewal script once outside the normal schedule.
    /// Any error is printed to standard output.
    public func triggerNow() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: scriptPath)
        do {
            try task.run()
        } catch {
            print("Certificate renewal failed: \(error)")
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
