import XCTest
@testable import FountainStoreClient

final class FountainStoreClientTests: XCTestCase {
    func testCorpusAndDocLifecycle() async throws {
        let client = FountainStoreClient(client: EmbeddedFountainStoreClient())
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
        let client = FountainStoreClient(client: EmbeddedFountainStoreClient())
        let caps = try await client.capabilities()
        XCTAssertTrue(caps.corpus)
        XCTAssertTrue(caps.documents.contains("upsert"))
    }

    func testMissingCapability() async throws {
        let caps = Capabilities(corpus: true, documents: ["upsert", "get", "delete"], query: [], transactions: [], admin: [], experimental: [])
        let client = FountainStoreClient(client: EmbeddedFountainStoreClient(caps: caps))
        do {
            _ = try await client.query(corpusId: "c1", collection: "pages", query: Query(mode: .byId("p1")))
            XCTFail("expected notSupported")
        } catch PersistenceError.notSupported(let need) {
            XCTAssertEqual(need, "query.byId")
        }
        let metrics = await client.capabilityRequests
        XCTAssertEqual(metrics["query.byId"], 1)
    }

    func testUnsupportedQueryShape() async throws {
        let client = FountainStoreClient(client: EmbeddedFountainStoreClient())
        let q = Query(mode: .byId("p1"), sort: [(field: "foo", ascending: true)])
        do {
            _ = try await client.query(corpusId: "c1", collection: "pages", query: q)
            XCTFail("expected notSupported")
        } catch PersistenceError.notSupported(let need) {
            XCTAssertEqual(need, "query.byId.invalid")
        }
        let metrics = await client.capabilityRequests
        XCTAssertEqual(metrics["query.byId.invalid"], 1)
    }

    func testCollectionHelpers() async throws {
        let client = FountainStoreClient(client: EmbeddedFountainStoreClient())
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

    func testListCorporaAndAdminOps() async throws {
        let client = FountainStoreClient(client: EmbeddedFountainStoreClient())
        _ = try await client.createCorpus("cA")
        _ = try await client.createCorpus("cB")
        let (total, corpora) = try await client.listCorpora()
        XCTAssertEqual(total, 2)
        XCTAssertEqual(Set(corpora), ["cA", "cB"])

        // Admin operations should succeed when capabilities are present
        try await client.backup(corpusId: "cA")
        try await client.compaction(corpusId: "cA")
    }

    func testExtendedCollections() async throws {
        let client = FountainStoreClient(client: EmbeddedFountainStoreClient())
        _ = try await client.createCorpus("c3")

        let baseline = Baseline(corpusId: "c3", baselineId: "b1", content: "base")
        _ = try await client.addBaseline(baseline)
        let reflection = Reflection(corpusId: "c3", reflectionId: "r1", question: "q", content: "a")
        _ = try await client.addReflection(reflection)
        let drift = Drift(corpusId: "c3", driftId: "d1", content: "dr")
        _ = try await client.addDrift(drift)
        let patterns = Patterns(corpusId: "c3", patternsId: "p1", content: "pat")
        _ = try await client.addPatterns(patterns)
        let role = Role(corpusId: "c3", name: "admin", prompt: "do")
        _ = try await client.addRole(role)
        _ = try await client.seedDefaultRoles(corpusId: "c3", defaults: [Role(corpusId: "c3", name: "user", prompt: "u")])

        let (_, baselines) = try await client.listBaselines(corpusId: "c3")
        XCTAssertEqual(baselines.first?.baselineId, "b1")
        let (_, reflections) = try await client.listReflections(corpusId: "c3")
        XCTAssertEqual(reflections.first?.reflectionId, "r1")
        let (_, drifts) = try await client.listDrifts(corpusId: "c3")
        XCTAssertEqual(drifts.first?.driftId, "d1")
        let (_, pats) = try await client.listPatterns(corpusId: "c3")
        XCTAssertEqual(pats.first?.patternsId, "p1")

        // verify roles inserted via query
        let roleResp = try await client.query(corpusId: "c3", collection: "roles", query: Query())
        XCTAssertEqual(roleResp.total, 2)
    }

    func testFunctionHelpers() async throws {
        let client = FountainStoreClient(client: EmbeddedFountainStoreClient())
        _ = try await client.createCorpus("c4")
        let fn = FunctionModel(corpusId: "c4", functionId: "f1", name: "fn", description: "desc", httpMethod: "GET", httpPath: "/f")
        _ = try await client.addFunction(fn)

        let (totalAll, all) = try await client.listFunctions()
        XCTAssertEqual(totalAll, 1)
        XCTAssertEqual(all.first?.functionId, "f1")

        let (totalCorpus, corpusFns) = try await client.listFunctions(corpusId: "c4")
        XCTAssertEqual(totalCorpus, 1)
        XCTAssertEqual(corpusFns.first?.functionId, "f1")

        let details = try await client.getFunctionDetails(functionId: "f1")
        XCTAssertEqual(details?.name, "fn")
    }

    func testSnapshotCapabilityFallback() async throws {
        let caps = Capabilities(corpus: true, documents: ["upsert", "get", "delete"], query: ["byId"], transactions: [], admin: [], experimental: [])
        let client = FountainStoreClient(client: EmbeddedFountainStoreClient(caps: caps))
        do {
            try await client.snapshot(corpusId: "c1")
            XCTFail("expected notSupported")
        } catch PersistenceError.notSupported(let need) {
            XCTAssertEqual(need, "transactions.snapshot")
        }
        let metrics = await client.capabilityRequests
        XCTAssertEqual(metrics["transactions.snapshot"], 1)
    }
}

