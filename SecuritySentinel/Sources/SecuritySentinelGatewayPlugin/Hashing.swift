import Foundation
import Crypto

enum Hashing {
    static func sha256Hex(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
