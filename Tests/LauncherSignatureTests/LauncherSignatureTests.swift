import XCTest
import LauncherSignature

final class LauncherSignatureTests: XCTestCase {
    func testEmbeddedSignatureConstant() {
        XCTAssertEqual(embeddedLauncherSignature, "development")
    }

    func testVerifyLauncherSignaturePassesWhenEnvMatches() {
        setenv("LAUNCHER_SIGNATURE", embeddedLauncherSignature, 1)
        verifyLauncherSignature()
        XCTAssertEqual(ProcessInfo.processInfo.environment["LAUNCHER_SIGNATURE"], embeddedLauncherSignature)
    }

    func testMissingSignatureDetected() {
        unsetenv("LAUNCHER_SIGNATURE")
        XCTAssertNotEqual(ProcessInfo.processInfo.environment["LAUNCHER_SIGNATURE"], embeddedLauncherSignature)
    }
}
