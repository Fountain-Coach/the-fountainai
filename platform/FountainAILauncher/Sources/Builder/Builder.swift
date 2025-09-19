import Foundation

enum BuilderError: Error, CustomStringConvertible {
    case buildFailed(String)

    var description: String {
        switch self {
        case .buildFailed(let product):
            return "swift build failed for product: \(product)"
        }
    }
}

struct Builder {
    struct Summary {
        let built: [Service]
        let failed: [(Service, Error)]
        var hasFailures: Bool { !failed.isEmpty }
    }

    static func build(
        services: [Service],
        signature: String,
        repositoryRoot: URL,
        progressHandler: ((BuildProgressEvent) -> Void)? = nil
    ) throws {
        // Embed launcher signature into shared library so each service
        // binary includes a compile-time token.
        let sigURL = repositoryRoot.appendingPathComponent("libs/LauncherSignature/Signature.swift")
        let sigContent = "public let embeddedLauncherSignature = \"\(signature)\"\n"
        try sigContent.write(to: sigURL, atomically: true, encoding: .utf8)

        // Ensure local module cache path exists to avoid permission issues
        let cacheDir = repositoryRoot.appendingPathComponent(".tmp/clang-cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        let uniqueServices = ServiceDeduplicator.uniquedByBinaryPath(services).unique
        for service in uniqueServices {
            let product = service.productName
            let process = Process()
            let (executable, arguments) = buildInvocation(for: product)
            process.executableURL = executable
            process.arguments = arguments
            process.currentDirectoryURL = repositoryRoot
            var environment = ProcessInfo.processInfo.environment
            environment["FULL_TESTS"] = "1"
            // Avoid SwiftPM sandbox and ensure clang module cache is writable
            environment["SWIFTPM_DISABLE_SANDBOX"] = environment["SWIFTPM_DISABLE_SANDBOX"] ?? "1"
            if environment["CLANG_MODULE_CACHE_PATH"] == nil {
                environment["CLANG_MODULE_CACHE_PATH"] = cacheDir.path
            }
            process.environment = environment

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            print("  • building \(product)…")

            // Prepare build log file
            let logsDir = repositoryRoot.appendingPathComponent("logs", isDirectory: true)
            try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
            let logURL = logsDir.appendingPathComponent("build-\(product).log")
            FileManager.default.createFile(atPath: logURL.path, contents: nil)
            let logHandle = try? FileHandle(forWritingTo: logURL)
            logHandle?.seekToEndOfFile()

            let tracker = BuildOutputTracker(product: product, handler: progressHandler, mirror: logHandle)

            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    handle.readabilityHandler = nil
                    return
                }
                FileHandle.standardOutput.write(data)
                fflush(stdout)
                if let chunk = String(data: data, encoding: .utf8) {
                    tracker.consume(chunk: chunk)
                }
            }

            try process.run()
            process.waitUntilExit()
            pipe.fileHandleForReading.readabilityHandler = nil
            tracker.finalize()
            try? logHandle?.close()

            if process.terminationStatus != 0 {
                throw BuilderError.buildFailed(product)
            }
            print("    ✓ \(product) built")
        }
    }

    /// Builds many services; continues on errors and returns a summary instead of throwing.
    static func buildAll(
        services: [Service],
        signature: String,
        repositoryRoot: URL,
        progressHandler: ((BuildProgressEvent) -> Void)? = nil
    ) -> Summary {
        // Embed signature as above
        let sigURL = repositoryRoot.appendingPathComponent("libs/LauncherSignature/Signature.swift")
        let sigContent = "public let embeddedLauncherSignature = \"\(signature)\"\n"
        try? sigContent.write(to: sigURL, atomically: true, encoding: .utf8)

        let cacheDir = repositoryRoot.appendingPathComponent(".tmp/clang-cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        let uniqueServices = ServiceDeduplicator.uniquedByBinaryPath(services).unique
        var built: [Service] = []
        var failed: [(Service, Error)] = []
        for service in uniqueServices {
            do {
                try buildProduct(service: service, repositoryRoot: repositoryRoot, progressHandler: progressHandler)
                built.append(service)
            } catch {
                failed.append((service, error))
            }
        }
        return Summary(built: built, failed: failed)
    }

    /// Builds a single product for a given service.
    @discardableResult
    static func buildProduct(
        service: Service,
        repositoryRoot: URL,
        progressHandler: ((BuildProgressEvent) -> Void)? = nil
    ) throws -> Void {
        let cacheDir = repositoryRoot.appendingPathComponent(".tmp/clang-cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        let product = service.productName
        let process = Process()
        let (executable, arguments) = buildInvocation(for: product)
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = repositoryRoot
        var environment = ProcessInfo.processInfo.environment
        environment["FULL_TESTS"] = "1"
        environment["SWIFTPM_DISABLE_SANDBOX"] = environment["SWIFTPM_DISABLE_SANDBOX"] ?? "1"
        if environment["CLANG_MODULE_CACHE_PATH"] == nil {
            environment["CLANG_MODULE_CACHE_PATH"] = cacheDir.path
        }
        process.environment = environment

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        print("  • building \(product)…")

        let logsDir = repositoryRoot.appendingPathComponent("logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        let logURL = logsDir.appendingPathComponent("build-\(product).log")
        FileManager.default.createFile(atPath: logURL.path, contents: nil)
        let logHandle = try? FileHandle(forWritingTo: logURL)
        logHandle?.seekToEndOfFile()

        let tracker = BuildOutputTracker(product: product, handler: progressHandler, mirror: logHandle)

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            FileHandle.standardOutput.write(data)
            fflush(stdout)
            if let chunk = String(data: data, encoding: .utf8) {
                tracker.consume(chunk: chunk)
            }
        }

        try process.run()
        process.waitUntilExit()
        pipe.fileHandleForReading.readabilityHandler = nil
        tracker.finalize()
        try? logHandle?.close()

        if process.terminationStatus != 0 {
            throw BuilderError.buildFailed(product)
        }
        print("    ✓ \(product) built")
    }
}

private extension Service {
    var productName: String {
        URL(fileURLWithPath: binaryPath).lastPathComponent
    }
}

private extension Builder {
    static func buildInvocation(for product: String) -> (URL, [String]) {
        let scriptPath = "/usr/bin/script"
        if FileManager.default.isExecutableFile(atPath: scriptPath) {
            let exe = URL(fileURLWithPath: scriptPath)
            let args = ["-q", "/dev/null", "swift", "build", "--configuration", "release", "--product", product]
            return (exe, args)
        }
        let exe = URL(fileURLWithPath: "/usr/bin/env")
        let args = ["swift", "build", "--configuration", "release", "--product", product]
        return (exe, args)
    }
}

enum BuildProgressEvent {
    case compile(module: String, index: Int)
    case link(artifact: String)
    case warning(String)
    case error(String)
}

private final class BuildOutputTracker: @unchecked Sendable {
    private var buffer = ""
    private var compileCount = 0
    private let product: String
    private let handler: ((BuildProgressEvent) -> Void)?
    private let queue = DispatchQueue(label: "build-output-tracker")
    private let mirror: FileHandle?

    init(product: String, handler: ((BuildProgressEvent) -> Void)?, mirror: FileHandle?) {
        self.product = product
        self.handler = handler
        self.mirror = mirror
    }

    func consume(chunk: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.buffer.append(chunk)
            while let range = self.buffer.range(of: "\n") {
                let line = String(self.buffer[..<range.lowerBound])
                self.buffer.removeSubrange(..<range.upperBound)
                self.process(line: line)
            }
        }
    }

    func finalize() {
        queue.sync {
            if !buffer.isEmpty {
                process(line: buffer)
                buffer.removeAll(keepingCapacity: false)
            }
        }
    }

    private func process(line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let module = extractCompileModule(from: trimmed) {
            compileCount += 1
            handler?(.compile(module: module, index: compileCount))
            mirror?.write(Data((trimmed + "\n").utf8))
            return
        }
        if let artifact = extractLinkArtifact(from: trimmed) {
            handler?(.link(artifact: artifact))
            mirror?.write(Data((trimmed + "\n").utf8))
            return
        }
        if trimmed.contains("warning:") {
            handler?(.warning(trimmed))
            mirror?.write(Data((trimmed + "\n").utf8))
        } else if trimmed.contains("error:") {
            handler?(.error(trimmed))
            mirror?.write(Data((trimmed + "\n").utf8))
        }
    }

    private func extractCompileModule(from line: String) -> String? {
        if let range = line.range(of: "Compile ") {
            let rest = line[range.upperBound...]
            let components = rest.split(whereSeparator: { $0 == " " || $0 == "(" })
            return components.first.map(String.init)
        }
        if let range = line.range(of: "Compiling ") {
            let rest = line[range.upperBound...]
            let components = rest.split(whereSeparator: { $0 == " " || $0 == "(" })
            return components.first.map(String.init)
        }
        return nil
    }

    private func extractLinkArtifact(from line: String) -> String? {
        if let range = line.range(of: "Linking ") {
            let rest = line[range.upperBound...]
            let components = rest.split(whereSeparator: { $0 == " " || $0 == "(" })
            return components.first.map(String.init)
        }
        return nil
    }
}
