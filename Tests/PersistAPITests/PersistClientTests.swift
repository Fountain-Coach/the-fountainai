import XCTest
@testable import PersistAPI
import ApiClientsCore

@MainActor
final class PersistClientTests: XCTestCase {
    override class func setUp() {
        URLProtocol.registerClass(MockURLProtocol.self)
    }
    override class func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
    }

    func testCapabilitiesDecode() async throws {
        MockURLProtocol.requestHandler = { req in
            XCTAssertEqual(req.url?.path, "/capabilities")
            let body = Data("{\"corpus\":true,\"query\":[\"byId\"]}".utf8)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
            return (resp, body)
        }
        let client = PersistClient(baseURL: URL(string: "http://persist.local")!)
        let caps = try await client.capabilities()
        XCTAssertEqual(caps.corpus, true)
        XCTAssertEqual(caps.query, ["byId"])
    }

    func testListCorpora() async throws {
        MockURLProtocol.requestHandler = { req in
            XCTAssertEqual(req.httpMethod, "GET")
            XCTAssertTrue(req.url!.absoluteString.contains("/corpora"))
            let body = Data("{\"total\":2,\"corpora\":[\"a\",\"b\"]}".utf8)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
            return (resp, body)
        }
        let client = PersistClient(baseURL: URL(string: "http://persist.local")!)
        let r = try await client.listCorpora()
        XCTAssertEqual(r.total, 2)
        XCTAssertEqual(r.corpora, ["a","b"])
    }

    func testReflectionsRoundtrip() async throws {
        // POST addReflection
        var phase = 0
        MockURLProtocol.requestHandler = { req in
            phase += 1
            if phase == 1 {
                XCTAssertEqual(req.httpMethod, "POST")
                XCTAssertTrue(req.url!.path.hasSuffix("/corpora/c1/reflections"))
                let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
                let body = Data("{\"message\":\"ok\"}".utf8)
                return (resp, body)
            } else {
                // GET listReflections
                let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
                let body = Data("{\"total\":1,\"reflections\":[{\"reflectionId\":\"r1\",\"corpusId\":\"c1\",\"question\":\"q\",\"content\":\"a\"}]}".utf8)
                return (resp, body)
            }
        }
        let client = PersistClient(baseURL: URL(string: "http://persist.local")!)
        let refl = Reflection(reflectionId: "r1", corpusId: "c1", question: "q", content: "a")
        let ack = try await client.addReflection(corpusId: "c1", reflection: refl)
        XCTAssertEqual(ack.message, "ok")
        let (total, items) = try await client.listReflections(corpusId: "c1")
        XCTAssertEqual(total, 1)
        XCTAssertEqual(items.first?.reflectionId, "r1")
    }

    func testListFunctionsAndDetails() async throws {
        var step = 0
        MockURLProtocol.requestHandler = { req in
            step += 1
            if req.url!.path.contains("/functions/") {
                let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
                let body = Data("{\"functionId\":\"f1\",\"corpusId\":\"c1\",\"name\":\"n\",\"description\":\"d\",\"httpMethod\":\"GET\",\"httpPath\":\"/x\"}".utf8)
                return (resp, body)
            } else {
                let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
                let body = Data("{\"total\":1,\"functions\":[{\"functionId\":\"f1\",\"corpusId\":\"c1\",\"name\":\"n\",\"description\":\"d\",\"httpMethod\":\"GET\",\"httpPath\":\"/x\"}]}".utf8)
                return (resp, body)
            }
        }
        let client = PersistClient(baseURL: URL(string: "http://persist.local")!)
        let list = try await client.listFunctions()
        XCTAssertEqual(list.total, 1)
        let d = try await client.getFunctionDetails(functionId: "f1")
        XCTAssertEqual(d?.functionId, "f1")
    }

    func testSeedingFlow() async throws {
        var step = 0
        MockURLProtocol.requestHandler = { req in
            step += 1
            if step == 1 {
                // POST /corpora
                XCTAssertEqual(req.httpMethod, "POST")
                XCTAssertEqual(req.url?.path, "/corpora")
                let resp = HTTPURLResponse(url: req.url!, statusCode: 201, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
                let body = Data("{\"corpusId\":\"gui\",\"message\":\"created\"}".utf8)
                return (resp, body)
            } else if step == 2 {
                // POST /corpora/{id}/baselines
                XCTAssertEqual(req.httpMethod, "POST")
                XCTAssertTrue(req.url!.path.hasSuffix("/corpora/gui/baselines"))
                let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
                let body = Data("{\"message\":\"ok\"}".utf8)
                return (resp, body)
            } else {
                // POST /corpora/{id}/reflections
                XCTAssertEqual(req.httpMethod, "POST")
                XCTAssertTrue(req.url!.path.hasSuffix("/corpora/gui/reflections"))
                let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
                let body = Data("{\"message\":\"ok\"}".utf8)
                return (resp, body)
            }
        }
        let client = PersistClient(baseURL: URL(string: "http://persist.local")!)
        let created = try await client.createCorpus(.init(corpusId: "gui"))
        XCTAssertEqual(created.corpusId, "gui")
        _ = try await client.addBaseline(corpusId: "gui", baseline: .init(baselineId: "b1", corpusId: "gui", content: "seed"))
        _ = try await client.addReflection(corpusId: "gui", reflection: .init(reflectionId: "r1", corpusId: "gui", question: "q", content: "a"))
    }
}

@MainActor
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else { return }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}
