import Foundation
#if canImport(Security)
import Security

public struct KeychainDefault: KeychainClient {
    public init() {}
    public func set(secret: Data, account: String) throws {
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                      kSecAttrAccount: account]
        SecItemDelete(query as CFDictionary)
        var add: [CFString: Any] = query
        add[kSecValueData] = secret
        let status = SecItemAdd(add as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }
    public func get(account: String) throws -> Data? {
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                      kSecAttrAccount: account,
                                      kSecReturnData: true,
                                      kSecMatchLimit: kSecMatchLimitOne]
        var out: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &out)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
        return out as? Data
    }
}
#else
public struct KeychainDefault: KeychainClient {
    public init() {}
    public func set(secret: Data, account: String) throws { }
    public func get(account: String) throws -> Data? { nil }
}
#endif

