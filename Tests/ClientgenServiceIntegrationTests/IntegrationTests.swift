import XCTest
import Foundation

/// Prerequisites: built executable in .build/debug; no special environment variables.
final class ClientgenServiceIntegrationTests: XCTestCase {
    func testShowsHelp() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ".build/debug/clientgen-service")
        process.arguments = ["--help"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertFalse(output.isEmpty)
    }

    func testShowsVersion() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ".build/debug/clientgen-service")
        process.arguments = ["--version"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertFalse(output.isEmpty)
    }

    func testInvalidArgumentsFail() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ".build/debug/clientgen-service")
        process.arguments = ["--bogus"]
        let pipe = Pipe()
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        let error = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        XCTAssertNotEqual(process.terminationStatus, 0)
        XCTAssertFalse(error.isEmpty)
    }
}
