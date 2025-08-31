import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import NIO
@testable import FountainRuntime

final class NIOHTTPServerTests: XCTestCase {
    /// Starts the server and verifies a simple request receives a response.
    func testServerResponds() async throws {
        let kernel = HTTPKernel { _ in HTTPResponse(status: 200, body: Data("hi".utf8)) }
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)
        let url = URL(string: "http://127.0.0.1:\(port)/")!
        let (data, response) = try await URLSession.shared.data(from: url)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(String(data: data, encoding: .utf8), "hi")
        try await server.stop()
    }

    /// Stopping the server should free the port allowing a subsequent bind.
    func testServerReleasesPortOnStop() async throws {
        let kernel = HTTPKernel { _ in HTTPResponse(status: 204) }
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)
        try await server.stop()
        let server2 = NIOHTTPServer(kernel: kernel)
        let boundPort = try await server2.start(port: port)
        XCTAssertEqual(boundPort, port)
        try await server2.stop()
    }

    /// The server should handle multiple simultaneous requests.
    func testServerHandlesConcurrentRequests() async throws {
        let kernel = HTTPKernel { _ in HTTPResponse(status: 200, body: Data("ok".utf8)) }
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)
        let url = URL(string: "http://127.0.0.1:\(port)/")!
        async let first = URLSession.shared.data(from: url)
        async let second = URLSession.shared.data(from: url)
        let (d1, r1) = try await first
        let (d2, r2) = try await second
        XCTAssertEqual((r1 as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual((r2 as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(String(data: d1, encoding: .utf8), "ok")
        XCTAssertEqual(String(data: d2, encoding: .utf8), "ok")
        try await server.stop()
    }

    /// SSE responses flagged with `X-Chunked-SSE` should flush events on chunk boundaries.
    func testSSEChunkBoundaries() async throws {
        let url = Bundle.module.url(forResource: "sse-stream", withExtension: "txt")!
        let payload = try Data(contentsOf: url)
        let kernel = HTTPKernel { _ in
            HTTPResponse(
                status: 200,
                headers: [
                    "Content-Type": "text/event-stream",
                    "Cache-Control": "no-cache",
                    "X-Chunked-SSE": "1"
                ],
                body: payload
            )
        }
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)
        let reqURL = URL(string: "http://127.0.0.1:\(port)/sse")!
        let (data, _) = try await URLSession.shared.data(from: reqURL)

        let text = String(decoding: data, as: UTF8.self)
        let events = text.split(separator: "\n\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        try await server.stop()
        XCTAssertEqual(events, [
            "event: a\ndata: 1",
            "event: b\ndata: 2"
        ])
    }

    /// Incoming headers should be normalized to lowercase for consistent lookup.
    func testHeaderNormalization() async throws {
        let kernel = HTTPKernel { req in
            XCTAssertEqual(req.headers["Content-Type"], "text/plain")
            return HTTPResponse(status: 204)
        }
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)
        var request = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/")!)
        request.httpMethod = "GET"
        request.addValue("text/plain", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 204)
        try await server.stop()
    }

    /// Empty request bodies should be delivered to the kernel unchanged.
    func testEmptyRequestBody() async throws {
        let kernel = HTTPKernel { req in
            XCTAssertEqual(req.body.count, 0)
            return HTTPResponse(status: 204)
        }
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)
        var request = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/echo")!)
        request.httpMethod = "POST"
        request.httpBody = Data()
        let (_, response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 204)
        try await server.stop()
    }

    /// Malformed HTTP requests should result in the connection being closed.
    func testMalformedRequestClosesConnection() async throws {
        let kernel = HTTPKernel { _ in HTTPResponse(status: 200) }
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)
        let fixture = Bundle.module.url(forResource: "malformed-request", withExtension: "txt")!
        let request = try String(contentsOf: fixture, encoding: .utf8)

        final class ReadHandler: ChannelInboundHandler, @unchecked Sendable {
            typealias InboundIn = ByteBuffer
            var promise: EventLoopPromise<ByteBuffer>?
            func channelRead(context: ChannelHandlerContext, data: NIOAny) {
                promise?.succeed(self.unwrapInboundIn(data))
            }
        }

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let readHandler = ReadHandler()
        let client = ClientBootstrap(group: group).channelInitializer { channel in
            channel.pipeline.addHandler(readHandler)
        }
        let channel = try await client.connect(host: "127.0.0.1", port: port).get()
        readHandler.promise = channel.eventLoop.makePromise()
        let buffer = channel.allocator.buffer(string: request)
        try await channel.writeAndFlush(buffer)
        let responseBuffer = try await readHandler.promise!.futureResult.get()
        let response = String(buffer: responseBuffer)
        XCTAssertTrue(response.contains("400"))
        try await channel.close()
        try await group.shutdownGracefully()
        try await server.stop()
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
