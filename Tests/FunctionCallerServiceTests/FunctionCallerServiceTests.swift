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
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
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

    func testGetFunctionDetailsNotFound() async throws {
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        let router = FunctionCallerRouter(persistence: svc)
        let resp = try await router.route(.init(method: "GET", path: "/functions/missing"))
        XCTAssertEqual(resp.status, 404)
        let err = try JSONDecoder().decode(ErrorResponse.self, from: resp.body)
        XCTAssertEqual(err.error_code, "not_found")
    }

    func testInvokeFunctionMissing() async throws {
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        let router = FunctionCallerRouter(persistence: svc)
        let resp = try await router.route(.init(method: "POST", path: "/functions/nope/invoke"))
        XCTAssertEqual(resp.status, 404)
        let err = try JSONDecoder().decode(ErrorResponse.self, from: resp.body)
        XCTAssertEqual(err.error_code, "not_found")
    }

    func testInvokeFunctionError() async throws {
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        let fn = FunctionModel(
            corpusId: "c1",
            functionId: "boom",
            name: "Boom",
            description: "desc",
            httpMethod: "GET",
            httpPath: "http://127.0.0.1:1/boom"
        )
        _ = try await svc.addFunction(fn)
        let router = FunctionCallerRouter(persistence: svc)
        let resp = try await router.route(.init(method: "POST", path: "/functions/boom/invoke"))
        XCTAssertEqual(resp.status, 500)
        let err = try JSONDecoder().decode(ErrorResponse.self, from: resp.body)
        XCTAssertEqual(err.error_code, "invoke_error")
    }

    func testMetricsEndpoint() async throws {
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        let router = FunctionCallerRouter(persistence: svc)
        let resp = try await router.route(.init(method: "GET", path: "/metrics"))
        XCTAssertEqual(resp.status, 200)
        let text = String(data: resp.body, encoding: .utf8) ?? ""
        XCTAssertTrue(text.contains("function_caller_requests_total"))
    }

    func testRouteNotFoundReturns404() async throws {
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        let router = FunctionCallerRouter(persistence: svc)
        let resp = try await router.route(.init(method: "GET", path: "/nope"))
        XCTAssertEqual(resp.status, 404)
    }

    func testParseQuery() {
        let params = FunctionCallerRouter.parseQuery("a=1&b=two")
        XCTAssertEqual(params["a"], "1")
        XCTAssertEqual(params["b"], "two")
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
