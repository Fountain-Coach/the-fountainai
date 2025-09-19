import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct PreflightOutcome {
    let note: String?
    let needsLocalStore: Bool
    let localStoreURL: URL?

    static let ok = PreflightOutcome(note: nil, needsLocalStore: false, localStoreURL: nil)
}

enum PreflightError: Error, CustomStringConvertible {
    case fountainStoreUnreachable(URL, underlying: Error?)

    var description: String {
        switch self {
        case let .fountainStoreUnreachable(url, underlying):
            if let underlying {
                return "Failed to reach FountainStore at \(url): \(underlying)"
            } else {
                return "Failed to reach FountainStore at \(url)"
            }
        }
    }
}

struct Preflight {
    /// Runs all preflight checks and returns outcome information.
    static func run() throws -> PreflightOutcome {
        try checkFountainStore()
    }

    private static func checkFountainStore(session: URLSession = .shared) throws -> PreflightOutcome {
        guard let urlString = ProcessInfo.processInfo.environment["FOUNTAINSTORE_URL"],
              let url = URL(string: urlString) else {
            return .ok
        }

        var request = URLRequest(url: url.appendingPathComponent("/health"))
        request.httpMethod = "GET"

        let semaphore = DispatchSemaphore(value: 0)
        let resultBox = ResultBox<Result<PreflightOutcome, Error>>(.success(.ok))

        let task = session.dataTask(with: request) { _, response, error in
            defer { semaphore.signal() }
            if let error {
                resultBox.store {
                    if isLocal(url: url) {
                        return .success(PreflightOutcome(
                            note: "FountainStore at \(url.absoluteString) is not reachable yet; will launch local persist service.",
                            needsLocalStore: true,
                            localStoreURL: URL(string: "http://127.0.0.1:8005")
                        ))
                    } else {
                        return .failure(PreflightError.fountainStoreUnreachable(url, underlying: error))
                    }
                }
                return
            }

            guard let http = response as? HTTPURLResponse else {
                resultBox.store {
                    if isLocal(url: url) {
                        return .success(PreflightOutcome(
                            note: "FountainStore at \(url.absoluteString) returned no response; continuing with local service start.",
                            needsLocalStore: true,
                            localStoreURL: URL(string: "http://127.0.0.1:8005")
                        ))
                    } else {
                        return .failure(PreflightError.fountainStoreUnreachable(url, underlying: nil))
                    }
                }
                return
            }

            guard (200..<300).contains(http.statusCode) else {
                let err = NSError(
                    domain: "Preflight",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"]
                )
                resultBox.store {
                    if isLocal(url: url) {
                        return .success(PreflightOutcome(
                            note: "FountainStore at \(url.absoluteString) responded with HTTP \(http.statusCode); attempting to launch local service.",
                            needsLocalStore: true,
                            localStoreURL: URL(string: "http://127.0.0.1:8005")
                        ))
                    } else {
                        return .failure(PreflightError.fountainStoreUnreachable(url, underlying: err))
                    }
                }
                return
            }
        }

        task.resume()
        _ = semaphore.wait(timeout: .now() + 5)

        switch resultBox.value {
        case .success(let outcome):
            return outcome
        case .failure(let error):
            throw error
        }
    }

    private static func isLocal(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host == "localhost" || host == "127.0.0.1" || host == "0.0.0.0"
    }
}

private final class ResultBox<Value>: @unchecked Sendable {
    private let queue = DispatchQueue(label: "preflight.result")
    private var storage: Value

    init(_ value: Value) {
        self.storage = value
    }

    func store(_ transform: () -> Value) {
        queue.sync {
            storage = transform()
        }
    }

    var value: Value {
        queue.sync { storage }
    }
}
