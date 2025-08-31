#if os(Linux)
import XCTest
import PDFiumExtractor
import Foundation

final class PDFiumExtractorTests: XCTestCase {
    func testInitialization() {
        _ = PDFiumExtractor()
    }

    func testRectInit() {
        let rect = Rect(x: 1, y: 2, width: 3, height: 4)
        XCTAssertEqual(rect.height, 4)
    }

    func testExtractionUnsupportedPlatformThrows() {
        let extractor = PDFiumExtractor()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("dummy.pdf")
        try? Data().write(to: url)
        XCTAssertThrowsError(try extractor.extractText(from: url))
    }
}
#endif
