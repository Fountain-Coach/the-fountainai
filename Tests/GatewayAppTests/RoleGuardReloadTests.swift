import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import gateway_server

final class RoleGuardReloadTests: XCTestCase {
    @MainActor
    func testListAndReloadRules() async throws {
        // Prepare a temp rules file
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let rulesFile = tmpDir.appendingPathComponent("roleguard.yml")
        let initial = """
        rules:
          "/awareness": "admin"
        """.data(using: .utf8)!
        try initial.write(to: rulesFile)

        // Server with store pointing to temp file
        let store = RoleGuardStore(initialRules: loadRoleGuardRules(path: rulesFile), configURL: rulesFile)
        let server = GatewayServer(plugins: [RoleGuardPlugin(store: store)], roleGuardStore: store)
        let port = 9145
        Task { try await server.start(port: port) }
        try await Task.sleep(nanoseconds: 100_000_000)

        // List rules
        let listURL = URL(string: "http://127.0.0.1:\(port)/roleguard")!
        let (data, resp) = try await URLSession.shared.data(from: listURL)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 200)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual((obj?["/awareness"] as? [String: Any]) != nil || (obj?["/awareness"] as? [String]) != nil, true)

        // Update file and reload
        let updated = """
        rules:
          "/bootstrap": "ops"
        """.data(using: .utf8)!
        try updated.write(to: rulesFile)

        var reloadReq = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/roleguard/reload")!)
        reloadReq.httpMethod = "POST"
        let (_, r2) = try await URLSession.shared.data(for: reloadReq)
        XCTAssertEqual((r2 as? HTTPURLResponse)?.statusCode, 204)

        // Verify new rules
        let (data3, resp3) = try await URLSession.shared.data(from: listURL)
        XCTAssertEqual((resp3 as? HTTPURLResponse)?.statusCode, 200)
        let obj3 = try JSONSerialization.jsonObject(with: data3) as? [String: Any]
        XCTAssertTrue(obj3?["/bootstrap"] != nil)

        try await server.stop()
    }
}

