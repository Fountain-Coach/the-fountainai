import XCTest
import NIOCore
import NIOEmbedded
@testable import FountainRuntime

final class DNSHandlerTests: XCTestCase {
    func makeQuery(name: String, type: UInt16) -> ByteBuffer {
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
        buf.writeInteger(type, as: UInt16.self)
        buf.writeInteger(UInt16(1), as: UInt16.self)
        return buf
    }

    final class RecordingHandler: ChannelOutboundHandler {
        typealias OutboundIn = ByteBuffer
        typealias OutboundOut = ByteBuffer
        var writeCount = 0
        func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
            writeCount += 1
            context.write(data, promise: promise)
        }
    }

    func testChannelReadForwardsResponse() throws {
        let engine = DNSEngine(records: [.init(name: "example.com", type: "A", value: "1.2.3.4")])
        let handler = DNSHandler(engine: engine)
        let recorder = RecordingHandler()
        let channel = EmbeddedChannel()
        try channel.pipeline.addHandlers(recorder, handler).wait()

        let query = makeQuery(name: "example.com", type: 1)
        channel.pipeline.fireChannelRead(NIOAny(query))
        channel.embeddedEventLoop.run()

        XCTAssertEqual(recorder.writeCount, 1)
        channel.pipeline.fireChannelReadComplete()
        _ = try channel.readOutbound() as ByteBuffer?
        XCTAssertTrue(try channel.finish().isClean)
    }

    func testChannelReadCompleteFlushesWrites() throws {
        let engine = DNSEngine(records: [.init(name: "example.com", type: "A", value: "1.2.3.4")])
        let channel = EmbeddedChannel(handler: DNSHandler(engine: engine))
        var query = makeQuery(name: "example.com", type: 1)
        channel.pipeline.fireChannelRead(NIOAny(query))
        let preFlush: ByteBuffer? = try channel.readOutbound()
        XCTAssertNil(preFlush)
        channel.pipeline.fireChannelReadComplete()
        let response: ByteBuffer? = try channel.readOutbound()
        XCTAssertNotNil(response)
        XCTAssertTrue(try channel.finish().isClean)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
