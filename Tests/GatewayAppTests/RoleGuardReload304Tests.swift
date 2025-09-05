import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import gateway_server

final class RoleGuardReload304Tests: XCTestCase {
    @MainActor
    func testReloadReturns304AndMetrics() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("roleguard.yml")
        try Data().write(to: file)
        let store = RoleGuardStore(initialRules: loadRoleGuardRules(path: file), configURL: file)
        let server = GatewayServer(plugins: [], roleGuardStore: store)
        let port = 9152
        Task { try await server.start(port: port) }
        try await Task.sleep(nanoseconds: 100_000_000)

        func metrics() async throws -> [String: Int] {
            let url = URL(string: "http://127.0.0.1:\(port)/metrics")!
            let (data, _) = try await URLSession.shared.data(from: url)
            return (try JSONSerialization.jsonObject(with: data) as? [String: Int]) ?? [:]
        }

        let m0 = try await metrics()
        let base304 = m0["gateway_responses_status_304_total"] ?? 0
        let baseReload = m0["roleguard_reload_total"] ?? 0

        let creds = CredentialStore()
        let admin = try creds.signJWT(subject: "c", expiresAt: Date().addingTimeInterval(3600), role: "admin")
        var req = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/roleguard/reload")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(admin)", forHTTPHeaderField: "Authorization")
        let (_, resp) = try await URLSession.shared.data(for: req)
        XCTAssertEqual((resp as? HTTPURLResponse)?.statusCode, 304)
        let m1 = try await metrics()
        XCTAssertEqual(m1["gateway_responses_status_304_total"] ?? 0, base304 + 1)
        XCTAssertEqual(m1["roleguard_reload_total"] ?? 0, baseReload)

        try await server.stop()
    }
}

