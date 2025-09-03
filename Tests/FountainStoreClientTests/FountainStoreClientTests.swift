import XCTest
@testable import FountainStoreClient

final class FountainStoreClientTests: XCTestCase {
    func testCorpusAndDocLifecycle() async throws {
        let client = FountainStoreClient(client: MockFountainStoreClient())
        _ = try await client.createCorpus("c1", metadata: ["owner": "me"])
        let corpus = try await client.getCorpus("c1")
        XCTAssertNotNil(corpus)

        let body = Data("{\"foo\":\"bar\"}".utf8)
        try await client.putDoc(corpusId: "c1", collection: "pages", id: "p1", body: body)
        let fetched = try await client.getDoc(corpusId: "c1", collection: "pages", id: "p1")
        XCTAssertNotNil(fetched)

        var resp = try await client.query(corpusId: "c1", collection: "pages", query: Query(mode: .byId("p1")))
        XCTAssertEqual(resp.total, 1)

        try await client.snapshot(corpusId: "c1")
        try await client.deleteDoc(corpusId: "c1", collection: "pages", id: "p1")
        resp = try await client.query(corpusId: "c1", collection: "pages", query: Query())
        XCTAssertEqual(resp.total, 0)
        try await client.restore(corpusId: "c1")
        resp = try await client.query(corpusId: "c1", collection: "pages", query: Query())
        XCTAssertEqual(resp.total, 1)

        try await client.deleteCorpus("c1")
        let removed = try await client.getCorpus("c1")
        XCTAssertNil(removed)
    }

    func testCapabilities() async throws {
        let client = FountainStoreClient(client: MockFountainStoreClient())
        let caps = try await client.capabilities()
        XCTAssertTrue(caps.corpus)
        XCTAssertTrue(caps.documents.contains("upsert"))
    }

    func testCollectionHelpers() async throws {
        let client = FountainStoreClient(client: MockFountainStoreClient())
        _ = try await client.createCorpus("c2")
        let page = Page(corpusId: "c2", pageId: "p1", url: "https://ex.com", host: "ex.com", title: "Ex")
        _ = try await client.addPage(page)
        let segment = Segment(corpusId: "c2", segmentId: "s1", pageId: "p1", kind: "paragraph", text: "hello")
        _ = try await client.addSegment(segment)
        let entity = Entity(corpusId: "c2", entityId: "e1", name: "Foo", type: "PERSON")
        _ = try await client.addEntity(entity)
        let table = Table(corpusId: "c2", tableId: "t1", pageId: "p1", csv: "a,b\n1,2")
        _ = try await client.addTable(table)
        let analysis = AnalysisRecord(corpusId: "c2", analysisId: "a1", pageId: "p1", summary: "ok")
        _ = try await client.addAnalysis(analysis)

        let (_, pages) = try await client.listPages(corpusId: "c2")
        XCTAssertEqual(pages.first?.pageId, "p1")
        let (_, segments) = try await client.listSegments(corpusId: "c2")
        XCTAssertEqual(segments.first?.segmentId, "s1")
        let (_, entities) = try await client.listEntities(corpusId: "c2")
        XCTAssertEqual(entities.first?.entityId, "e1")
        let (_, tables) = try await client.listTables(corpusId: "c2")
        XCTAssertEqual(tables.first?.tableId, "t1")
        let (_, analyses) = try await client.listAnalyses(corpusId: "c2")
        XCTAssertEqual(analyses.first?.analysisId, "a1")
    }
}

