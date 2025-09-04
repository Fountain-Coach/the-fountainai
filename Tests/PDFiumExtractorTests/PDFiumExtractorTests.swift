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

    func testOpenFailedError() {
        let mock = MockPDFium(openSuccess: false)
        let extractor = PDFiumExtractor(pdfium: mock)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("dummy.pdf")
        XCTAssertThrowsError(try extractor.extractText(from: url, useOCR: false)) { error in
            XCTAssertEqual(error as? PDFiumExtractorError, .openFailed)
        }
    }

    func testSuccessfulExtraction() throws {
        let mock = MockPDFium(openSuccess: true)
        let extractor = PDFiumExtractor(pdfium: mock)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("dummy.pdf")
        let fragments = try extractor.extractText(from: url, useOCR: false)
        XCTAssertEqual(fragments.count, 1)
        XCTAssertEqual(fragments.first?.text, "H")
    }
}

private final class MockPDFium: PDFiumLibrary {
    let isAvailable = true
    let openSuccess: Bool
    init(openSuccess: Bool) { self.openSuccess = openSuccess }
    func loadDocument(_ path: String, _ password: UnsafePointer<CChar>?) -> FPDFDocument? {
        openSuccess ? FPDFDocument(bitPattern: 1) : nil
    }
    func closeDocument(_ document: FPDFDocument) {}
    func getPageCount(_ document: FPDFDocument) -> Int32 { 1 }
    func loadPage(_ document: FPDFDocument, _ pageIndex: Int32) -> FPDFPage? {
        FPDFPage(bitPattern: 1)
    }
    func closePage(_ page: FPDFPage) {}
    func textLoadPage(_ page: FPDFPage) -> FPDFTextPage? { FPDFTextPage(bitPattern: 1) }
    func textClosePage(_ textPage: FPDFTextPage) {}
    func textCountChars(_ textPage: FPDFTextPage) -> Int32 { 1 }
    func textGetCharBox(_ textPage: FPDFTextPage, _ index: Int32, _ left: inout Double, _ right: inout Double, _ bottom: inout Double, _ top: inout Double) {
        left = 0; right = 1; bottom = 0; top = 1
    }
    func textGetText(_ textPage: FPDFTextPage, _ startIndex: Int32, _ count: Int32, _ buffer: inout [UInt16], _ bufferSize: Int32) -> Int32 {
        buffer[0] = Array("H".utf16)[0]
        return 1
    }
}
#endif
