import Foundation
import Yams

public func roleGuardConfigURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL {
    return environment["ROLE_GUARD_PATH"].map(URL.init(fileURLWithPath:)) ?? URL(fileURLWithPath: "Configuration/roleguard.yml")
}

public func loadRoleGuardRules(from path: URL? = nil, environment: [String: String] = ProcessInfo.processInfo.environment) -> [String: RoleRequirement] {
    let url = path ?? roleGuardConfigURL(environment: environment)
    guard FileManager.default.fileExists(atPath: url.path), let text = try? String(contentsOf: url, encoding: .utf8) else { return [:] }
    do {
        if let yaml = try Yams.load(yaml: text) as? [String: Any], let rawRules = yaml["rules"] as? [String: Any] {
            var result: [String: RoleRequirement] = [:]
            for (prefix, val) in rawRules {
                if let s = val as? String {
                    result[prefix] = RoleRequirement(roles: [s])
                } else if let arr = val as? [String] {
                    result[prefix] = RoleRequirement(roles: arr)
                } else if let dict = val as? [String: Any] {
                    let roles = dict["roles"] as? [String]
                    let scopes = dict["scopes"] as? [String]
                    result[prefix] = RoleRequirement(roles: roles, scopes: scopes, requireAllScopes: ( (dict["scopes_mode"] as? String)?.lowercased() == "all" ) || (dict["require_all_scopes"] as? Bool ?? false), methods: (dict["methods"] as? [String])?.map { $0.uppercased() }, deny: dict["deny"] as? Bool ?? false)
                }
            }
            return result
        }
    } catch {
        // ignore parse errors
    }
    return [:]
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
