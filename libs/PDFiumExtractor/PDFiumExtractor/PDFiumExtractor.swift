import Foundation
#if canImport(PDFium)
import PDFium
#endif

public struct Rect: Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct PDFTextFragment: Sendable {
    public let text: String
    public let frame: Rect
    public init(text: String, frame: Rect) {
        self.text = text
        self.frame = frame
    }
}

public enum PDFiumExtractorError: Error {
    case unsupportedPlatform
    case openFailed
}

public final class PDFiumExtractor {
    private let pdfium: PDFiumLibrary
    public init(pdfium: PDFiumLibrary = DefaultPDFiumLibrary()) {
        self.pdfium = pdfium
    }
    public func extractText(from url: URL, useOCR: Bool = true) throws -> [PDFTextFragment] {
        guard pdfium.isAvailable else {
            throw PDFiumExtractorError.unsupportedPlatform
        }
        var fragments: [PDFTextFragment] = []
        guard let document = pdfium.loadDocument(url.path, nil) else {
            throw PDFiumExtractorError.openFailed
        }
        defer { pdfium.closeDocument(document) }
        let pageCount = pdfium.getPageCount(document)
        for pageIndex in 0..<pageCount {
            guard let page = pdfium.loadPage(document, pageIndex) else { continue }
            defer { pdfium.closePage(page) }
            guard let textPage = pdfium.textLoadPage(page) else { continue }
            defer { pdfium.textClosePage(textPage) }
            let charCount = pdfium.textCountChars(textPage)
            for i in 0..<charCount {
                var left: Double = 0, right: Double = 0, bottom: Double = 0, top: Double = 0
                pdfium.textGetCharBox(textPage, i, &left, &right, &bottom, &top)
                var buffer = [UInt16](repeating: 0, count: 8)
                let count = pdfium.textGetText(textPage, i, 1, &buffer, Int32(buffer.count))
                if count > 0 {
                    let text = String(decoding: buffer[0..<Int(count)], as: UTF16.self)
                    let rect = Rect(x: left, y: bottom, width: right - left, height: top - bottom)
                    fragments.append(PDFTextFragment(text: text, frame: rect))
                }
            }
#if canImport(PDFium)
            if useOCR, hasTesseract {
                fragments += ocrText(in: page)
            }
#endif
        }
        return fragments
    }
}

#if canImport(PDFium)
private var hasTesseract: Bool = {
    let which = Process()
    which.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    which.arguments = ["which", "tesseract"]
    let pipe = Pipe()
    which.standardOutput = pipe
    try? which.run()
    which.waitUntilExit()
    return which.terminationStatus == 0
}()

private func ocrText(in page: FPDF_PAGE?) -> [PDFTextFragment] {
    guard hasTesseract, let page = page else { return [] }
    var results: [PDFTextFragment] = []
    let count = FPDFPage_CountObjects(page)
    for index in 0..<count {
        guard let obj = FPDFPage_GetObject(page, index), FPDFPageObj_GetType(obj) == FPDF_PAGEOBJ_IMAGE else { continue }
        var left: Double = 0, right: Double = 0, bottom: Double = 0, top: Double = 0
        FPDFPageObj_GetBounds(obj, &left, &right, &bottom, &top)
        guard let bitmap = FPDFImageObj_GetBitmap(obj), let data = FPDFBitmapGetPNGData(bitmap) else { continue }
        if let text = runTesseract(on: data) {
            let rect = Rect(x: left, y: bottom, width: right - left, height: top - bottom)
            results.append(PDFTextFragment(text: text, frame: rect))
        }
    }
    return results
}

private func runTesseract(on data: Data) -> String? {
    let tempDir = FileManager.default.temporaryDirectory
    let imageURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
    let outputBase = tempDir.appendingPathComponent(UUID().uuidString)
    do {
        try data.write(to: imageURL)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "tesseract")
        process.arguments = [imageURL.path, outputBase.path]
        try process.run()
        process.waitUntilExit()
        let txtURL = outputBase.appendingPathExtension("txt")
        let text = try String(contentsOf: txtURL, encoding: .utf8)
        try? FileManager.default.removeItem(at: imageURL)
        try? FileManager.default.removeItem(at: txtURL)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
        return nil
    }
}

// Placeholder for a helper provided by the PDFium wrapper to emit PNG data from a bitmap.
private func FPDFBitmapGetPNGData(_ bitmap: FPDF_BITMAP) -> Data? {
    // Actual implementation would use the wrapper's facilities to encode the bitmap into PNG.
    return nil
}
#endif

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
