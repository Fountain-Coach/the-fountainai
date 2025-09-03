import XCTest
@testable import FunctionCallerService
@testable import FountainStoreClient
import FountainRuntime

final class FunctionCallerServiceTests: XCTestCase {
    func startStubServer() async throws -> (port: Int, shutdown: () async throws -> Void) {
        let kernel = HTTPKernel { req in
            return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: req.body)
        }
        let server = NIOHTTPServer(kernel: kernel)
        let port = try await server.start(port: 0)
        return (port, { try await server.stop() })
    }

    func testListDetailAndInvoke() async throws {
        let stub = try await startStubServer()
        defer { try? await stub.shutdown() }
        let svc = FountainStoreClient(client: MockFountainStoreClient())
        let fn = FunctionModel(corpusId: "c1", functionId: "echo", name: "Echo", description: "desc", httpMethod: "POST", httpPath: "http://127.0.0.1:\(stub.port)/echo")
        _ = try await svc.addFunction(fn)
        let router = FunctionCallerRouter(persistence: svc)

        let listResp = try await router.route(.init(method: "GET", path: "/functions"))
        XCTAssertEqual(listResp.status, 200)
        let list = try JSONDecoder().decode(FunctionsListResponse.self, from: listResp.body)
        XCTAssertEqual(list.total, 1)
        XCTAssertEqual(list.functions.first?.function_id, "echo")

        let detailResp = try await router.route(.init(method: "GET", path: "/functions/echo"))
        XCTAssertEqual(detailResp.status, 200)
        let info = try JSONDecoder().decode(FunctionInfo.self, from: detailResp.body)
        XCTAssertEqual(info.http_path, "http://127.0.0.1:\(stub.port)/echo")

        let body = try JSONSerialization.data(withJSONObject: ["foo": "bar"])
        let invokeResp = try await router.route(.init(method: "POST", path: "/functions/echo/invoke", body: body))
        XCTAssertEqual(invokeResp.status, 200)
        let obj = try JSONSerialization.jsonObject(with: invokeResp.body) as? [String: String]
        XCTAssertEqual(obj?["foo"], "bar")
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
