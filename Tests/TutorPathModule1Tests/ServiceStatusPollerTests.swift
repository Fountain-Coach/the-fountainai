import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import TutorDashboard

@MainActor
final class ServiceStatusPollerTests: XCTestCase {
    func testFetchStatusUsesEnvironmentOverrideAndParsesCapabilities() async {
        StubURLProtocol.clear()
        let descriptor = ServiceDescriptor(
            fileName: "bootstrap.yml",
            title: "FountainAI Bootstrap Service",
            binaryName: "bootstrap",
            port: 8002,
            servers: [],
            healthPaths: ["/health"],
            capabilityPaths: ["/capabilities"]
        )

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer {
            session.invalidateAndCancel()
            StubURLProtocol.clear()
        }

        let healthURL = URL(string: "http://127.0.0.1:9000/health")!
        let capabilitiesURL = URL(string: "http://127.0.0.1:9000/capabilities")!

        StubURLProtocol.register(
            url: healthURL,
            response: .success(statusCode: 200, body: Data("{\"status\":\"ok\"}".utf8))
        )
        StubURLProtocol.register(
            url: capabilitiesURL,
            response: .success(
                statusCode: 200,
                body: Data("{\"corpus\":true,\"documents\":[\"read\",\"write\"],\"empty\":[],\"flag\":false}".utf8)
            )
        )

        let poller = ServiceStatusPoller(session: session)
        let statuses = await poller.fetchStatus(
            for: [descriptor],
            environment: ["BOOTSTRAP_URL": "http://127.0.0.1:9000"]
        )

        XCTAssertEqual(statuses.count, 1)
        guard let status = statuses.first else {
            XCTFail("Expected status")
            return
        }

        XCTAssertEqual(status.baseURL.absoluteString, "http://127.0.0.1:9000")
        XCTAssertEqual(status.health.first?.path, "/health")
        XCTAssertEqual(status.health.first?.statusCode, 200)
        XCTAssertTrue(status.health.first?.ok ?? false)

        XCTAssertEqual(status.capabilities.first?.path, "/capabilities")
        XCTAssertTrue(status.capabilities.first?.ok ?? false)
        XCTAssertEqual(status.capabilities.first?.capabilities, ["corpus", "documents"])
        XCTAssertEqual(status.capabilities.first?.missingCapabilities, ["empty", "flag"])
    }

    func testFetchStatusCapturesFailures() async {
        StubURLProtocol.clear()
        let descriptor = ServiceDescriptor(
            fileName: "planner.yml",
            title: "FountainAI Planner Service",
            binaryName: "planner",
            port: 8003,
            servers: [URL(string: "http://planner.local")!],
            healthPaths: ["/health"],
            capabilityPaths: []
        )

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer {
            session.invalidateAndCancel()
            StubURLProtocol.clear()
        }

        let failingURL = URL(string: "http://planner.local/health")!
        StubURLProtocol.register(url: failingURL, response: .error(URLError(.notConnectedToInternet)))

        let poller = ServiceStatusPoller(session: session)
        let statuses = await poller.fetchStatus(for: [descriptor])

        XCTAssertEqual(statuses.count, 1)
        guard let status = statuses.first else {
            XCTFail("Missing planner status")
            return
        }

        XCTAssertEqual(status.baseURL.absoluteString, "http://planner.local")
        XCTAssertEqual(status.health.count, 1)
        XCTAssertFalse(status.health[0].ok)
        XCTAssertNil(status.health[0].statusCode)
        XCTAssertNotNil(status.health[0].message)
    }
}

@MainActor
private final class StubURLProtocol: URLProtocol {
    enum Response {
        case success(statusCode: Int, body: Data, headers: [String: String] = [:])
        case error(Error)
    }

    nonisolated(unsafe) private static var handlers: [URL: Response] = [:]

    nonisolated static func register(url: URL, response: Response) {
        handlers[url] = response
    }

    nonisolated static func clear() {
        handlers.removeAll()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return handlers[url] != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        guard let response = StubURLProtocol.handlers[url] else {
            client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable))
            return
        }

        switch response {
        case let .success(statusCode, body, headers):
            guard let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: headers
            ) else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case let .error(error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
