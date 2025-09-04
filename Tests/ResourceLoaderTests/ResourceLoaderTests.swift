import XCTest
import ResourceLoader
#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif

final class ResourceLoaderTests: XCTestCase {
    func testValidFile() throws {
        let bundle = Bundle.module
        let expectedURL = bundle.url(forResource: "valid", withExtension: "txt")!
        let url = try ResourceLoader.url("valid", ext: "txt", subdir: nil, bundle: bundle)
        XCTAssertEqual(url, expectedURL)
        let data = try ResourceLoader.data("valid", ext: "txt", subdir: nil, bundle: bundle)
        XCTAssertEqual(data, try Data(contentsOf: expectedURL))
    }

    func testMissingFile() throws {
        XCTAssertThrowsError(try ResourceLoader.url("no-such-file", ext: "txt", subdir: nil, bundle: Bundle(for: Self.self))) { error in
            guard case ResourceError.missing(let path) = error else {
                return XCTFail("Expected ResourceError.missing, got \(error)")
            }
            XCTAssertEqual(path, "no-such-file.txt")
            XCTAssertTrue(error.localizedDescription.contains("Resource missing"))
        }
    }

    func testTraversalDoesNotEscapeRoot() throws {
        XCTAssertThrowsError(try ResourceLoader.url("secret", ext: "txt", subdir: "..", bundle: Bundle(for: Self.self))) { error in
            guard case ResourceError.missing(let path) = error else {
                return XCTFail("Expected ResourceError.missing, got \(error)")
            }
            XCTAssertEqual(path, "../secret.txt")
        }
    }

    func testUnreadableFile() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let resourceDir = tempDir.appendingPathComponent("unreadable.txt", isDirectory: true)
        try FileManager.default.createDirectory(at: resourceDir, withIntermediateDirectories: true)
        let bundle = Bundle(path: tempDir.path)!
        XCTAssertThrowsError(try ResourceLoader.data("unreadable", ext: "txt", subdir: nil, bundle: bundle)) { error in
            guard case ResourceError.unreadable(let desc, _) = error else {
                return XCTFail("Expected ResourceError.unreadable, got \(error)")
            }
            XCTAssertEqual(desc, resourceDir.path)
            XCTAssertTrue(error.localizedDescription.contains("Failed to read resource"))
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
