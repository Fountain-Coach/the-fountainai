import XCTest
import MIDI2Models

final class MIDI2Tests: XCTestCase {
    func testModelIndexInitialization() {
        let doc = MIDIModelIndex.Document(fileName: "file", id: "1", pages: [], sha256: "abc", size: 1)
        let index = MIDIModelIndex(documents: [doc])
        XCTAssertEqual(index.documents.count, 1)
        XCTAssertEqual(index.documents.first?.id, "1")
    }

    func testLoadFromValidJSON() throws {
        let json = "{\"documents\":[]}" 
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("index.json")
        try json.write(to: url, atomically: true, encoding: .utf8)
        let index = try MIDIModelIndex.load(from: url.path)
        XCTAssertEqual(index.documents.count, 0)
    }

    func testLoadInvalidJSONThrows() {
        let bad = "not json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("bad.json")
        try? bad.write(to: url, atomically: true, encoding: .utf8)
        XCTAssertThrowsError(try MIDIModelIndex.load(from: url.path))
    }
}
