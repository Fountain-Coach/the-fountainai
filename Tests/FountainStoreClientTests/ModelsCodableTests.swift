import XCTest
@testable import FountainStoreClient

final class FountainStoreClientModelsCodableTests: XCTestCase {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func testCorpusCodable() throws {
        let model = Corpus(id: "c1", metadata: ["owner": "me"])
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(Corpus.self, from: data)
        XCTAssertEqual(decoded.id, "c1")
        XCTAssertEqual(decoded.metadata["owner"], "me")
    }

    func testCorpusCreateRequestCodable() throws {
        let model = CorpusCreateRequest(corpusId: "cid")
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(CorpusCreateRequest.self, from: data)
        XCTAssertEqual(decoded.corpusId, "cid")
    }

    func testCorpusResponseCodable() throws {
        let model = CorpusResponse(corpusId: "cid", message: "ok")
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(CorpusResponse.self, from: data)
        XCTAssertEqual(decoded.corpusId, "cid")
        XCTAssertEqual(decoded.message, "ok")
    }

    func testBaselineCodable() throws {
        let model = Baseline(corpusId: "c", baselineId: "b", content: "base", ts: 1)
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(Baseline.self, from: data)
        XCTAssertEqual(decoded.corpusId, "c")
        XCTAssertEqual(decoded.baselineId, "b")
        XCTAssertEqual(decoded.content, "base")
        XCTAssertEqual(decoded.ts, 1)
    }

    func testReflectionCodable() throws {
        let model = Reflection(corpusId: "c", reflectionId: "r", question: "q", content: "a", ts: 2)
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(Reflection.self, from: data)
        XCTAssertEqual(decoded.reflectionId, "r")
        XCTAssertEqual(decoded.question, "q")
        XCTAssertEqual(decoded.content, "a")
        XCTAssertEqual(decoded.ts, 2)
    }

    func testDriftCodable() throws {
        let model = Drift(corpusId: "c", driftId: "d", content: "dr", ts: 3)
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(Drift.self, from: data)
        XCTAssertEqual(decoded.driftId, "d")
        XCTAssertEqual(decoded.content, "dr")
        XCTAssertEqual(decoded.ts, 3)
    }

    func testPatternsCodable() throws {
        let model = Patterns(corpusId: "c", patternsId: "p", content: "pat", ts: 4)
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(Patterns.self, from: data)
        XCTAssertEqual(decoded.patternsId, "p")
        XCTAssertEqual(decoded.content, "pat")
        XCTAssertEqual(decoded.ts, 4)
    }

    func testRoleCodable() throws {
        let model = Role(corpusId: "c", name: "admin", prompt: "do")
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(Role.self, from: data)
        XCTAssertEqual(decoded.name, "admin")
        XCTAssertEqual(decoded.prompt, "do")
    }

    func testPageCodable() throws {
        let model = Page(corpusId: "c", pageId: "p1", url: "https://x", host: "x", title: "t")
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(Page.self, from: data)
        XCTAssertEqual(decoded.pageId, "p1")
        XCTAssertEqual(decoded.url, "https://x")
        XCTAssertEqual(decoded.host, "x")
        XCTAssertEqual(decoded.title, "t")
    }

    func testSegmentCodable() throws {
        let model = Segment(corpusId: "c", segmentId: "s", pageId: "p", kind: "k", text: "txt")
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(Segment.self, from: data)
        XCTAssertEqual(decoded.segmentId, "s")
        XCTAssertEqual(decoded.pageId, "p")
        XCTAssertEqual(decoded.kind, "k")
        XCTAssertEqual(decoded.text, "txt")
    }

    func testEntityCodable() throws {
        let model = Entity(corpusId: "c", entityId: "e", name: "N", type: "T")
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(Entity.self, from: data)
        XCTAssertEqual(decoded.entityId, "e")
        XCTAssertEqual(decoded.name, "N")
        XCTAssertEqual(decoded.type, "T")
    }

    func testTableCodable() throws {
        let model = Table(corpusId: "c", tableId: "t1", pageId: "p", csv: "a,b")
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(Table.self, from: data)
        XCTAssertEqual(decoded.tableId, "t1")
        XCTAssertEqual(decoded.pageId, "p")
        XCTAssertEqual(decoded.csv, "a,b")
    }

    func testAnalysisRecordCodable() throws {
        let model = AnalysisRecord(corpusId: "c", analysisId: "a", pageId: "p", summary: "s")
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(AnalysisRecord.self, from: data)
        XCTAssertEqual(decoded.analysisId, "a")
        XCTAssertEqual(decoded.pageId, "p")
        XCTAssertEqual(decoded.summary, "s")
    }

    func testCapabilitiesCodable() throws {
        let model = Capabilities(corpus: true, documents: ["upsert"], query: ["byId"], transactions: ["snapshot"], admin: ["health"], experimental: [])
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(Capabilities.self, from: data)
        XCTAssertTrue(decoded.corpus)
        XCTAssertEqual(decoded.documents.first, "upsert")
        XCTAssertEqual(decoded.query.first, "byId")
        XCTAssertEqual(decoded.transactions.first, "snapshot")
        XCTAssertEqual(decoded.admin.first, "health")
    }

    func testFunctionModelCodable() throws {
        let model = FunctionModel(corpusId: "c", functionId: "f", name: "fn", description: "desc", httpMethod: "GET", httpPath: "/f")
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(FunctionModel.self, from: data)
        XCTAssertEqual(decoded.functionId, "f")
        XCTAssertEqual(decoded.name, "fn")
        XCTAssertEqual(decoded.description, "desc")
        XCTAssertEqual(decoded.httpMethod, "GET")
        XCTAssertEqual(decoded.httpPath, "/f")
    }

    func testSuccessResponseCodable() throws {
        let model = SuccessResponse(message: "ok")
        let data = try encoder.encode(model)
        let decoded = try decoder.decode(SuccessResponse.self, from: data)
        XCTAssertEqual(decoded.message, "ok")
    }
}

