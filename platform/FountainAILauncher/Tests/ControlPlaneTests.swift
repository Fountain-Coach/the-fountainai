import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import FountainAiLauncher

final class ControlPlaneTests: XCTestCase {
    func testHTTPKernelHandleRoutesRequestsAndPropagatesErrors() async throws {
        enum TestError: Error { case boom }
        let kernel = HTTPKernel { req in
            if req.path == "/ok" {
                return HTTPResponse(status: 201)
            } else {
                throw TestError.boom
            }
        }
        let success = try await kernel.handle(HTTPRequest(method: "GET", path: "/ok"))
        XCTAssertEqual(success.status, 201)
        do {
            _ = try await kernel.handle(HTTPRequest(method: "GET", path: "/fail"))
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    func testHTTPResponseDefaults() {
        let resp = HTTPResponse()
        XCTAssertEqual(resp.status, 200)
        XCTAssertTrue(resp.headers.isEmpty)
        XCTAssertTrue(resp.body.isEmpty)
    }

    func testNIOHTTPServerBasicCycle() async throws {
        let kernel = HTTPKernel { _ in
            HTTPResponse(status: 200, headers: ["Content-Type": "text/plain"], body: Data("hello".utf8))
        }
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)
        let url = URL(string: "http://127.0.0.1:\(port)/")!
        let (data, response) = try await URLSession.shared.data(from: url)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(String(data: data, encoding: .utf8), "hello")
        try await server.stop()
    }

    func testSSEChunkingEmitsSeparateEvents() async throws {
        let sseBody = "data: one\n\n" + "data: two\n\n"
        let kernel = HTTPKernel { _ in
            HTTPResponse(
                status: 200,
                headers: [
                    "Content-Type": "text/event-stream",
                    "X-Chunked-SSE": "1"
                ],
                body: Data(sseBody.utf8)
            )
        }
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)

        let chunkExp = expectation(description: "chunks")
        chunkExp.expectedFulfillmentCount = 2
        let doneExp = expectation(description: "done")

        final class Delegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
            var chunks: [String] = []
            let chunkExp: XCTestExpectation
            let doneExp: XCTestExpectation
            init(chunkExp: XCTestExpectation, doneExp: XCTestExpectation) {
                self.chunkExp = chunkExp
                self.doneExp = doneExp
            }
            func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
                if let s = String(data: data, encoding: .utf8) {
                    chunks.append(s)
                }
                chunkExp.fulfill()
            }
            func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
                doneExp.fulfill()
            }
        }

        let delegate = Delegate(chunkExp: chunkExp, doneExp: doneExp)
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: URL(string: "http://127.0.0.1:\(port)/sse")!)
        task.resume()
        await fulfillment(of: [chunkExp, doneExp], timeout: 5.0)
        XCTAssertEqual(delegate.chunks, ["data: one\n\n", "data: two\n\n"])
        session.invalidateAndCancel()
        try await server.stop()
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
