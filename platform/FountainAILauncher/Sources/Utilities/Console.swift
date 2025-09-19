import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

enum Console {
    static let isTTY: Bool = {
        #if canImport(Darwin)
        return isatty(STDOUT_FILENO) == 1
        #elseif canImport(Glibc)
        return isatty(STDOUT_FILENO) == 1
        #else
        return false
        #endif
    }()

    enum Style: String {
        case reset = "\u{001B}[0m"
        case bold = "\u{001B}[1m"
        case dim = "\u{001B}[2m"
        case red = "\u{001B}[31m"
        case green = "\u{001B}[32m"
        case yellow = "\u{001B}[33m"
        case blue = "\u{001B}[34m"
        case magenta = "\u{001B}[35m"
        case cyan = "\u{001B}[36m"
    }

    static func apply(_ text: String, styles: [Style]) -> String {
        guard isTTY, !styles.isEmpty else { return text }
        let codes = styles.map { $0.rawValue }.joined()
        return codes + text + Style.reset.rawValue
    }

    static func apply(_ text: String, _ style: Style) -> String {
        apply(text, styles: [style])
    }

    static func bold(_ text: String) -> String { apply(text, .bold) }
    static func dim(_ text: String) -> String { apply(text, .dim) }
    static func green(_ text: String) -> String { apply(text, .green) }
    static func yellow(_ text: String) -> String { apply(text, .yellow) }
    static func red(_ text: String) -> String { apply(text, .red) }
    static func cyan(_ text: String) -> String { apply(text, .cyan) }
}

final class Spinner {
    private static let frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    private var message: String
    private let interval: TimeInterval
    private var timer: DispatchSourceTimer?
    private var frameIndex: Int = 0
    private var lastRenderedCount: Int = 0
    private var heartbeat: Heartbeat?
    private let lock = NSLock()

    init(message: String, interval: TimeInterval = 0.1) {
        self.message = message
        self.interval = interval
    }

    func start() {
        if Console.isTTY {
            let timer = DispatchSource.makeTimerSource(queue: DispatchQueue(label: "spinner"))
            timer.schedule(deadline: .now(), repeating: interval)
            timer.setEventHandler { [weak self] in self?.tick() }
            timer.resume()
            self.timer = timer
        } else {
            let hb = Heartbeat(message: message)
            hb.start()
            heartbeat = hb
        }
    }

    func stop(success: Bool) {
        if Console.isTTY {
            timer?.cancel()
            timer = nil
            renderFinal(success: success)
        } else {
            heartbeat?.stop()
            heartbeat = nil
        }
    }

    func update(message: String) {
        lock.lock()
        self.message = message
        lock.unlock()
    }

    private func tick() {
        lock.lock()
        let frame = Spinner.frames[frameIndex % Spinner.frames.count]
        frameIndex += 1
        let currentMessage = message
        lock.unlock()
        render(frame: frame, trailing: "", message: currentMessage)
    }

    private func render(frame: String, trailing: String, message: String? = nil) {
        let msg = message ?? self.message
        var line = "\r\(frame) \(msg)\(trailing)"
        let visibleCount = line.count
        if lastRenderedCount > visibleCount {
            line += String(repeating: " ", count: lastRenderedCount - visibleCount)
        }
        lastRenderedCount = visibleCount
        if let data = line.data(using: .utf8) {
            FileHandle.standardOutput.write(data)
            fflush(stdout)
        }
    }

    private func renderFinal(success: Bool) {
        let symbol = success ? "✓" : "✗"
        render(frame: symbol, trailing: "")
        lastRenderedCount = 0
        if let data = "\n".data(using: .utf8) {
            FileHandle.standardOutput.write(data)
            fflush(stdout)
        }
    }
}
