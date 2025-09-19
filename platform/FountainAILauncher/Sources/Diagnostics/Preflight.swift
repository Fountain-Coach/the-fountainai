import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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
    /// Runs preflight checks and returns an optional human-readable note for non-fatal warnings.
    static func run() throws -> String? {
        try checkFountainStore()
    }

    private static func checkFountainStore(session: URLSession = .shared) throws -> String? {
        guard let urlString = ProcessInfo.processInfo.environment["FOUNTAINSTORE_URL"], let url = URL(string: urlString) else {
            return nil
        }
        var request = URLRequest(url: url.appendingPathComponent("/health"))
        request.httpMethod = "GET"
        let semaphore = DispatchSemaphore(value: 0)
        var finalResult: Result<String?, Error> = .success(nil)
        let resultQueue = DispatchQueue(label: "preflight.store")
        let task = session.dataTask(with: request) { _, response, error in
            defer { semaphore.signal() }
            if let error {
                resultQueue.sync {
                    if isLocal(url: url) {
                        finalResult = .success("FountainStore at \(url.absoluteString) is not reachable yet; will launch local persist service.")
                    } else {
                        finalResult = .failure(PreflightError.fountainStoreUnreachable(url, underlying: error))
                    }
                }
                return
            }
            guard let http = response as? HTTPURLResponse else {
                resultQueue.sync {
                    if isLocal(url: url) {
                        finalResult = .success("FountainStore at \(url.absoluteString) returned no response; continuing with local service start.")
                    } else {
                        finalResult = .failure(PreflightError.fountainStoreUnreachable(url, underlying: nil))
                    }
                }
                return
            }
            guard (200..<300).contains(http.statusCode) else {
                let err = NSError(domain: "Preflight", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
                resultQueue.sync {
                    if isLocal(url: url) {
                        finalResult = .success("FountainStore at \(url.absoluteString) responded with HTTP \(http.statusCode); attempting to launch local service.")
                    } else {
                        finalResult = .failure(PreflightError.fountainStoreUnreachable(url, underlying: err))
                    }
                }
                return
            }
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 5)
        let outcome = resultQueue.sync { finalResult }
        switch outcome {
        case .success(let note):
            return note
        case .failure(let error):
            throw error
        }
    }

    private static func isLocal(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host == "localhost" || host == "127.0.0.1" || host == "0.0.0.0"
    }
}
