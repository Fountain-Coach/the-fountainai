import XCTest
@testable import ToolServerService
import ToolServer
import Yams

struct MockAdapter: ToolAdapter {
    let data: Data
    let code: Int32
    let tool: String
    func run(args: [String]) throws -> (Data, Int32) { (data, code) }
}

final class ToolServerHandlersTests: XCTestCase {
    func testRunFFmpegReturnsOutput() async throws {
        let h = Handlers(ffmpegAdapter: MockAdapter(data: Data("ok".utf8), code: 0, tool: "ffmpeg"))
        let router = Router(handlers: h)
        let req = ToolRequest(args: ["-version"], request_id: "r1")
        let body = try JSONEncoder().encode(req)
        let resp = try await router.route(.init(method: "POST", path: "/ffmpeg", body: body))
        XCTAssertEqual(resp.status, 200)
        XCTAssertEqual(String(data: resp.body, encoding: .utf8), "ok")
    }

    func testPdfScanReturnsIndex() async throws {
        let idx = Index(documents: [["id": "d1"]])
        let data = try JSONEncoder().encode(idx)
        let h = Handlers(pdfScanAdapter: MockAdapter(data: data, code: 0, tool: "pdf-scan"))
        let router = Router(handlers: h)
        let req = ScanRequest(includeText: false, inputs: ["a.pdf"], sha256: false)
        let body = try JSONEncoder().encode(req)
        let resp = try await router.route(.init(method: "POST", path: "/pdf/scan", body: body))
        XCTAssertEqual(resp.status, 200)
        let out = try JSONDecoder().decode(Index.self, from: resp.body)
        XCTAssertEqual(out.documents.first?["id"], "d1")
    }

    func testPdfQueryReturnsHits() async throws {
        let hits = QueryResponse(hits: [["docId": "d1", "page": "1", "snippet": "x"]])
        let data = try JSONEncoder().encode(hits)
        let h = Handlers(pdfQueryAdapter: MockAdapter(data: data, code: 0, tool: "pdf-query"))
        let router = Router(handlers: h)
        let req = QueryRequest(index: Index(documents: []), pageRange: "", q: "x")
        let body = try JSONEncoder().encode(req)
        let resp = try await router.route(.init(method: "POST", path: "/pdf/query", body: body))
        XCTAssertEqual(resp.status, 200)
        let out = try JSONDecoder().decode(QueryResponse.self, from: resp.body)
        XCTAssertEqual(out.hits.count, 1)
    }

    func testPdfExportMatrixReturnsMatrix() async throws {
        let matrix = Matrix(bitfields: [], enums: [], messages: [], ranges: [], schemaVersion: "1", terms: [])
        let data = try JSONEncoder().encode(matrix)
        let h = Handlers(pdfExportMatrixAdapter: MockAdapter(data: data, code: 0, tool: "pdf-export-matrix"))
        let router = Router(handlers: h)
        let req = ExportMatrixRequest(bitfields: false, enums: false, index: Index(documents: []), ranges: false)
        let body = try JSONEncoder().encode(req)
        let resp = try await router.route(.init(method: "POST", path: "/pdf/export-matrix", body: body))
        XCTAssertEqual(resp.status, 200)
        let out = try JSONDecoder().decode(Matrix.self, from: resp.body)
        XCTAssertEqual(out.schemaVersion, "1")
    }

    func testOpenAPISpecLoads() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // ToolServerHandlersTests.swift
            .deletingLastPathComponent() // ToolServerTests
            .deletingLastPathComponent() // Tests
        let url = root.appendingPathComponent("openapi/v1/tool-server.yml")
        let text = try String(contentsOf: url, encoding: .utf8)
        let obj = try Yams.load(yaml: text)
        XCTAssertNotNil(obj)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
