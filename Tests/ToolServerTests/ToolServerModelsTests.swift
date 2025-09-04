import XCTest
@testable import ToolServerService

final class ToolServerModelsTests: XCTestCase {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func testBitFieldCodable() throws {
        let model = BitField(bits: [1,2], name: "flags")
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(BitField.self, from: data)
        XCTAssertEqual(decoded.bits, [1,2])
        XCTAssertEqual(decoded.name, "flags")
    }

    func testEnumCaseCodable() throws {
        let model = EnumCase(name: "foo", value: 1)
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(EnumCase.self, from: data)
        XCTAssertEqual(decoded.name, "foo")
        XCTAssertEqual(decoded.value, 1)
    }

    func testEnumSpecCodable() throws {
        let model = EnumSpec(cases: [EnumCase(name: "a", value: 0)], field: "f")
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(EnumSpec.self, from: data)
        XCTAssertEqual(decoded.cases.first?.name, "a")
        XCTAssertEqual(decoded.field, "f")
    }

    func testExportMatrixRequestCodable() throws {
        let model = ExportMatrixRequest(bitfields: true, enums: true, index: Index(documents: [["id": "1"]]), ranges: false)
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(ExportMatrixRequest.self, from: data)
        XCTAssertTrue(decoded.bitfields)
        XCTAssertTrue(decoded.enums)
        XCTAssertEqual(decoded.index.documents.first?["id"], "1")
        XCTAssertFalse(decoded.ranges)
    }

    func testIndexCodable() throws {
        let model = Index(documents: [["id": "x"], ["id": "y"]])
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(Index.self, from: data)
        XCTAssertEqual(decoded.documents.count, 2)
        XCTAssertEqual(decoded.documents.first?["id"], "x")
    }

    func testMatrixCodable() throws {
        let bf = BitField(bits: [0], name: "b")
        let enumSpec = EnumSpec(cases: [EnumCase(name: "c", value: 1)], field: "f")
        let entry = MatrixEntry(page: 1, text: "t", x: 0, y: 1)
        let range = RangeSpec(field: "f", max: 10, min: 0)
        let model = Matrix(bitfields: [bf], enums: [enumSpec], messages: [entry], ranges: [range], schemaVersion: "1", terms: [entry])
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(Matrix.self, from: data)
        XCTAssertEqual(decoded.schemaVersion, "1")
        XCTAssertEqual(decoded.bitfields.first?.name, "b")
        XCTAssertEqual(decoded.enums.first?.field, "f")
        XCTAssertEqual(decoded.messages.first?.page, 1)
        XCTAssertEqual(decoded.ranges.first?.max, 10)
        XCTAssertEqual(decoded.terms.first?.text, "t")
    }

    func testMatrixEntryCodable() throws {
        let model = MatrixEntry(page: 2, text: "x", x: 3, y: 4)
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(MatrixEntry.self, from: data)
        XCTAssertEqual(decoded.page, 2)
        XCTAssertEqual(decoded.text, "x")
        XCTAssertEqual(decoded.x, 3)
        XCTAssertEqual(decoded.y, 4)
    }

    func testQueryRequestCodable() throws {
        let model = QueryRequest(index: Index(documents: []), pageRange: "1-2", q: "foo")
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(QueryRequest.self, from: data)
        XCTAssertEqual(decoded.pageRange, "1-2")
        XCTAssertEqual(decoded.q, "foo")
    }

    func testQueryResponseCodable() throws {
        let model = QueryResponse(hits: [["docId": "d1"]])
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(QueryResponse.self, from: data)
        XCTAssertEqual(decoded.hits.first?["docId"], "d1")
    }

    func testRangeSpecCodable() throws {
        let model = RangeSpec(field: "f", max: 5, min: 1)
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(RangeSpec.self, from: data)
        XCTAssertEqual(decoded.field, "f")
        XCTAssertEqual(decoded.max, 5)
        XCTAssertEqual(decoded.min, 1)
    }

    func testScanRequestCodable() throws {
        let model = ScanRequest(includeText: true, inputs: ["a"], sha256: true)
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(ScanRequest.self, from: data)
        XCTAssertTrue(decoded.includeText)
        XCTAssertEqual(decoded.inputs, ["a"])
        XCTAssertTrue(decoded.sha256)
    }

    func testToolRequestCodable() throws {
        let model = ToolRequest(args: ["-v"], request_id: "r1")
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(ToolRequest.self, from: data)
        XCTAssertEqual(decoded.args, ["-v"])
        XCTAssertEqual(decoded.request_id, "r1")
    }

    func testValidationResultCodable() throws {
        let model = ValidationResult(issues: ["a"], ok: true)
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(ValidationResult.self, from: data)
        XCTAssertEqual(decoded.issues, ["a"])
        XCTAssertTrue(decoded.ok)
    }
}

