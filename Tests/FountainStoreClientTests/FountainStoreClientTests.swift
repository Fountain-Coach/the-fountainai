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
}

