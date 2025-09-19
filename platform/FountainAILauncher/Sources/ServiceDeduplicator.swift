import Foundation

/// Collapses duplicate services that point to the same binary path.
enum ServiceDeduplicator {
    /// Returns the first service for every unique binary path along with
    /// any duplicates that were skipped.
    /// - Parameter services: Input set of services (potentially with duplicates).
    /// - Returns: Tuple containing unique services and grouped duplicates keyed by binary path.
    static func uniquedByBinaryPath(_ services: [Service]) -> (unique: [Service], duplicates: [String: [Service]]) {
        var seen = Set<String>()
        var unique: [Service] = []
        var duplicates: [String: [Service]] = [:]
        for service in services {
            let key = service.binaryPath
            if seen.insert(key).inserted {
                unique.append(service)
            } else {
                duplicates[key, default: []].append(service)
            }
        }
        return (unique, duplicates)
    }
}

