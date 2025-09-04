import Foundation
#if canImport(PDFium)
import PDFium
#endif

public typealias FPDFDocument = OpaquePointer
public typealias FPDFPage = OpaquePointer
public typealias FPDFTextPage = OpaquePointer

public protocol PDFiumLibrary {
    var isAvailable: Bool { get }
    func loadDocument(_ path: String, _ password: UnsafePointer<CChar>?) -> FPDFDocument?
    func closeDocument(_ document: FPDFDocument)
    func getPageCount(_ document: FPDFDocument) -> Int32
    func loadPage(_ document: FPDFDocument, _ pageIndex: Int32) -> FPDFPage?
    func closePage(_ page: FPDFPage)
    func textLoadPage(_ page: FPDFPage) -> FPDFTextPage?
    func textClosePage(_ textPage: FPDFTextPage)
    func textCountChars(_ textPage: FPDFTextPage) -> Int32
    func textGetCharBox(_ textPage: FPDFTextPage, _ index: Int32, _ left: inout Double, _ right: inout Double, _ bottom: inout Double, _ top: inout Double)
    func textGetText(_ textPage: FPDFTextPage, _ startIndex: Int32, _ count: Int32, _ buffer: inout [UInt16], _ bufferSize: Int32) -> Int32
}

#if canImport(PDFium)
public struct DefaultPDFiumLibrary: PDFiumLibrary {
    public init() {}
    public var isAvailable: Bool { true }
    public func loadDocument(_ path: String, _ password: UnsafePointer<CChar>?) -> FPDFDocument? {
        FPDF_LoadDocument(path, password)
    }
    public func closeDocument(_ document: FPDFDocument) {
        FPDF_CloseDocument(document)
    }
    public func getPageCount(_ document: FPDFDocument) -> Int32 {
        FPDF_GetPageCount(document)
    }
    public func loadPage(_ document: FPDFDocument, _ pageIndex: Int32) -> FPDFPage? {
        FPDF_LoadPage(document, pageIndex)
    }
    public func closePage(_ page: FPDFPage) {
        FPDF_ClosePage(page)
    }
    public func textLoadPage(_ page: FPDFPage) -> FPDFTextPage? {
        FPDFText_LoadPage(page)
    }
    public func textClosePage(_ textPage: FPDFTextPage) {
        FPDFText_ClosePage(textPage)
    }
    public func textCountChars(_ textPage: FPDFTextPage) -> Int32 {
        FPDFText_CountChars(textPage)
    }
    public func textGetCharBox(_ textPage: FPDFTextPage, _ index: Int32, _ left: inout Double, _ right: inout Double, _ bottom: inout Double, _ top: inout Double) {
        FPDFText_GetCharBox(textPage, index, &left, &right, &bottom, &top)
    }
    public func textGetText(_ textPage: FPDFTextPage, _ startIndex: Int32, _ count: Int32, _ buffer: inout [UInt16], _ bufferSize: Int32) -> Int32 {
        buffer.withUnsafeMutableBufferPointer { ptr in
            FPDFText_GetText(textPage, startIndex, count, ptr.baseAddress, bufferSize)
        }
    }
}
#else
public struct DefaultPDFiumLibrary: PDFiumLibrary {
    public init() {}
    public var isAvailable: Bool { false }
    public func loadDocument(_ path: String, _ password: UnsafePointer<CChar>?) -> FPDFDocument? { nil }
    public func closeDocument(_ document: FPDFDocument) {}
    public func getPageCount(_ document: FPDFDocument) -> Int32 { 0 }
    public func loadPage(_ document: FPDFDocument, _ pageIndex: Int32) -> FPDFPage? { nil }
    public func closePage(_ page: FPDFPage) {}
    public func textLoadPage(_ page: FPDFPage) -> FPDFTextPage? { nil }
    public func textClosePage(_ textPage: FPDFTextPage) {}
    public func textCountChars(_ textPage: FPDFTextPage) -> Int32 { 0 }
    public func textGetCharBox(_ textPage: FPDFTextPage, _ index: Int32, _ left: inout Double, _ right: inout Double, _ bottom: inout Double, _ top: inout Double) {}
    public func textGetText(_ textPage: FPDFTextPage, _ startIndex: Int32, _ count: Int32, _ buffer: inout [UInt16], _ bufferSize: Int32) -> Int32 { 0 }
}
#endif
