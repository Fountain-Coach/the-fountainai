import XCTest
@testable import LauncherSignature

final class LauncherSignatureTests: XCTestCase {
    func testEmbeddedSignatureConstant() {
        XCTAssertEqual(embeddedLauncherSignature, "development")
    }

    func testVerifyLauncherSignaturePassesWhenEnvMatches() {
        setenv("LAUNCHER_SIGNATURE", embeddedLauncherSignature, 1)
        verifyLauncherSignature()
        XCTAssertEqual(
            ProcessInfo.processInfo.environment["LAUNCHER_SIGNATURE"],
            embeddedLauncherSignature
        )
    }

    func testMissingSignatureFailsValidation() {
        unsetenv("LAUNCHER_SIGNATURE")
        XCTAssertFalse(isLauncherSignatureValid())
    }

    func testInvalidSignatureFailsValidation() {
        setenv("LAUNCHER_SIGNATURE", "bogus", 1)
        XCTAssertFalse(isLauncherSignatureValid())
    }
}
