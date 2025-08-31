import XCTest
import Crypto
@testable import FountainRuntime

final class DNSSECSignerTests: XCTestCase {
    func testSignAndVerifyZone() throws {
        let key = Curve25519.Signing.PrivateKey()
        let signer = DNSSECSigner(privateKey: key)
        let zone = "example.com: 1.2.3.4"
        let sig = try signer.sign(zone: zone)
        XCTAssertTrue(signer.verify(zone: zone, signature: sig))
    }

    func testVerifyFailsForTamperedZone() throws {
        let key = Curve25519.Signing.PrivateKey()
        let signer = DNSSECSigner(privateKey: key)
        let zone = "example.com: 1.2.3.4"
        let sig = try signer.sign(zone: zone)
        let tampered = zone + "5"
        XCTAssertFalse(signer.verify(zone: tampered, signature: sig))
    }

    func testVerifyFailsWithDifferentKey() throws {
        let signer1 = DNSSECSigner(privateKey: Curve25519.Signing.PrivateKey())
        let signer2 = DNSSECSigner(privateKey: Curve25519.Signing.PrivateKey())
        let zone = "example.com: 1.2.3.4"
        let sig = try signer1.sign(zone: zone)
        XCTAssertFalse(signer2.verify(zone: zone, signature: sig))
    }

    func testPublicKeyValidatesSignature() throws {
        let key = Curve25519.Signing.PrivateKey()
        let signer = DNSSECSigner(privateKey: key)
        let zone = "example.com: 1.2.3.4"
        let sig = try signer.sign(zone: zone)
        XCTAssertTrue(signer.publicKey.isValidSignature(sig, for: Data(zone.utf8)))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

