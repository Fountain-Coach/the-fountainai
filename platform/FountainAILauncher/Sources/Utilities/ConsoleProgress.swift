import Foundation

/// Coordinates human-friendly phase updates for the launcher.
final class PhaseReporter {
    private let total: Int
    private var index: Int = 0

    init(total: Int) {
        self.total = max(total, 1)
    }

    func begin(_ name: String) -> PhaseContext {
        index += 1
        return PhaseContext(name: name, index: index, total: total)
    }
}

/// Tracks the lifetime of a single launcher phase.
final class PhaseContext {
    private let name: String
    private let index: Int
    private let total: Int
    private let startedAt: Date
    private var completed = false

    init(name: String, index: Int, total: Int) {
        self.name = name
        self.index = index
        self.total = total
        self.startedAt = Date()
        let prefix = Console.apply("▶︎", .cyan)
        let text = Console.apply("\(name)…", .dim)
        announce(prefix: prefix, text: text)
    }

    func succeed(note: String? = nil) {
        guard !completed else { return }
        completed = true
        let duration = Date().timeIntervalSince(startedAt)
        let suffix = note.map { " – \($0)" } ?? ""
        let prefix = Console.apply("✅", .green)
        let message = "\(Console.bold(name)) completed in \(format(duration))s\(suffix)"
        announce(prefix: prefix, text: message)
    }

    func fail(with error: Error) {
        guard !completed else { return }
        completed = true
        let duration = Date().timeIntervalSince(startedAt)
        let prefix = Console.apply("❌", .red)
        let message = "\(Console.bold(name)) failed after \(format(duration))s: \(error)"
        announce(prefix: prefix, text: message)
    }

    @discardableResult
    func execute(spinnerMessage: String? = nil, work: () throws -> String?) rethrows -> String? {
        var spinner: Spinner?
        if let spinnerMessage = spinnerMessage {
            spinner = Spinner(message: spinnerMessage)
            spinner?.start()
        }
        do {
            let note = try work()
            spinner?.stop(success: true)
            succeed(note: note)
            return note
        } catch {
            spinner?.stop(success: false)
            fail(with: error)
            throw error
        }
    }

    private func announce(prefix: String, text: String) {
        print("[\(index)/\(total)] \(prefix) \(text)")
        fflush(stdout)
    }

    private func format(_ interval: TimeInterval) -> String {
        String(format: "%.1f", interval)
    }
}

/// Emits a steady heartbeat message so the user knows long-running tasks are active.
final class Heartbeat {
    private let message: String
    private let interval: TimeInterval
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "heartbeat")

    init(message: String, interval: TimeInterval = 5) {
        self.message = message
        self.interval = interval
    }

    func start() {
        guard timer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler { [message] in
            print(message)
            fflush(stdout)
        }
        timer.resume()
        self.timer = timer
    }

    func stop() {
        queue.sync {
            timer?.cancel()
            timer = nil
        }
    }
}
