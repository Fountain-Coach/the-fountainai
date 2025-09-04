import XCTest
import Foundation
import NIOCore
import NIOPosix
@testable import FountainRuntime

final class DNSServerTCPTests: XCTestCase {
    static func makeQuery(name: String) -> ByteBuffer {
        var buf = ByteBufferAllocator().buffer(capacity: 512)
        buf.writeInteger(UInt16(0x1234), as: UInt16.self)
        buf.writeInteger(UInt16(0), as: UInt16.self)
        buf.writeInteger(UInt16(1), as: UInt16.self)
        buf.writeInteger(UInt16(0), as: UInt16.self)
        buf.writeInteger(UInt16(0), as: UInt16.self)
        buf.writeInteger(UInt16(0), as: UInt16.self)
        for label in name.split(separator: ".") {
            let bytes = Array(label.utf8)
            buf.writeInteger(UInt8(bytes.count), as: UInt8.self)
            buf.writeBytes(bytes)
        }
        buf.writeInteger(UInt8(0), as: UInt8.self)
        buf.writeInteger(UInt16(1), as: UInt16.self)
        buf.writeInteger(UInt16(1), as: UInt16.self)
        return buf
    }

    static func extractIPv4(_ buf: ByteBuffer) -> String? {
        guard buf.readableBytes >= 4 else { return nil }
        let start = buf.readerIndex + buf.readableBytes - 4
        guard let b1: UInt8 = buf.getInteger(at: start),
              let b2: UInt8 = buf.getInteger(at: start + 1),
              let b3: UInt8 = buf.getInteger(at: start + 2),
              let b4: UInt8 = buf.getInteger(at: start + 3) else { return nil }
        return "\(b1).\(b2).\(b3).\(b4)"
    }

    func testServerRespondsToTCPQueries() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let manager = try ZoneManager(fileURL: tmp, enableGitCommits: false)
        let zone = try await manager.createZone(name: "example.com")
        _ = try await manager.createRecord(zoneId: zone.id, name: "", type: "A", value: "1.2.3.4")
        let server = await DNSServer(zoneManager: manager)
        let port = Int.random(in: 20000..<40000)
        _ = try await server.start(udpPort: port, tcpPort: port)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let promise = group.next().makePromise(of: [ByteBuffer].self)
        let channel = try await ClientBootstrap(group: group)
            .channelInitializer { channel in
                channel.pipeline.addHandler(TCPResponseHandler(promise: promise, expectedCount: 2))
            }
            .connect(host: "127.0.0.1", port: port).get()

        var q1 = Self.makeQuery(name: "example.com")
        var q2 = Self.makeQuery(name: "example.com")
        var buffer = channel.allocator.buffer(capacity: q1.readableBytes + q2.readableBytes + 4)
        buffer.writeInteger(UInt16(q1.readableBytes), as: UInt16.self)
        buffer.writeBuffer(&q1)
        buffer.writeInteger(UInt16(q2.readableBytes), as: UInt16.self)
        buffer.writeBuffer(&q2)
        try await channel.writeAndFlush(buffer).get()

        let responses = try await promise.futureResult.get()
        XCTAssertEqual(responses.count, 2)
        XCTAssertEqual(Self.extractIPv4(responses[0]), "1.2.3.4")
        XCTAssertEqual(Self.extractIPv4(responses[1]), "1.2.3.4")

        try await channel.close().get()
        try await server.stop()
        try await group.shutdownGracefully()
    }

    func testHandlesIncompleteFrame() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let manager = try ZoneManager(fileURL: tmp, enableGitCommits: false)
        let zone = try await manager.createZone(name: "example.com")
        _ = try await manager.createRecord(zoneId: zone.id, name: "", type: "A", value: "1.2.3.4")
        let server = await DNSServer(zoneManager: manager)
        let port = Int.random(in: 20000..<40000)
        _ = try await server.start(udpPort: port, tcpPort: port)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let channel = try await ClientBootstrap(group: group).connect(host: "127.0.0.1", port: port).get()
        var buf = channel.allocator.buffer(capacity: 2)
        buf.writeInteger(UInt16(10), as: UInt16.self)
        try await channel.writeAndFlush(buf).get()
        try await Task.sleep(nanoseconds: 100_000_000)
        try await channel.close().get()
        try await server.stop()
        try await group.shutdownGracefully()
    }
}

final class TCPResponseHandler: ChannelInboundHandler, @unchecked Sendable {
    typealias InboundIn = ByteBuffer
    let promise: EventLoopPromise<[ByteBuffer]>
    let expectedCount: Int
    private var buffer = ByteBuffer()
    private var responses: [ByteBuffer] = []

    init(promise: EventLoopPromise<[ByteBuffer]>, expectedCount: Int) {
        self.promise = promise
        self.expectedCount = expectedCount
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var newData = self.unwrapInboundIn(data)
        buffer.writeBuffer(&newData)
        while true {
            guard let length: UInt16 = buffer.getInteger(at: buffer.readerIndex) else { break }
            let total = Int(length) + 2
            guard buffer.readableBytes >= total else { break }
            buffer.moveReaderIndex(forwardBy: 2)
            if let slice = buffer.readSlice(length: Int(length)) {
                responses.append(slice)
                if responses.count == expectedCount {
                    promise.succeed(responses)
                }
            }
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
