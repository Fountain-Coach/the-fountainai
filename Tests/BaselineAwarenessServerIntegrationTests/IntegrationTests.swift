import XCTest
import Foundation

/// Prerequisites: built executable in .build/debug; no special environment variables.
final class BaselineAwarenessServerIntegrationTests: XCTestCase {
    func testRunsWithHelp() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ".build/debug/baseline-awareness-server")
        process.arguments = ["--help"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: data, as: UTF8.self)
        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertFalse(output.isEmpty)
    }
}
