import XCTest
import Foundation
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

    func testVerifyLauncherSignatureFailsWithInvalidEnv() {
        setenv("LAUNCHER_SIGNATURE", "bogus", 1)
        var status: Int32?
        let mockExit: (Int32) -> Void = { code in status = code }

        let pipe = Pipe()
        let fd = dup(STDERR_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        verifyLauncherSignature(exit: mockExit)

        fflush(nil)
        dup2(fd, STDERR_FILENO)
        pipe.fileHandleForWriting.closeFile()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        XCTAssertEqual(status, 1)
        XCTAssertTrue(output.contains("Missing or invalid launcher signature"))

        unsetenv("LAUNCHER_SIGNATURE")
    }
}
