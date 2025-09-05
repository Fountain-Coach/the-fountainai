import XCTest
import FountainStoreClient
@testable import gateway_server

final class RoleGuardConfigTests: XCTestCase {
    func testLoadRoleGuardRulesFromYAML() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("roleguard.yml")
        let yaml = """
        rules:
          "/awareness": "admin"
          "/bootstrap": "admin"
        """
        try yaml.write(to: file, atomically: true, encoding: .utf8)
        let rules = loadRoleGuardRules(path: file)
        XCTAssertEqual(rules["/awareness"]?.roles ?? [], ["admin"])
        XCTAssertEqual(rules["/bootstrap"]?.roles ?? [], ["admin"])
    }
}

    func testLoadRoleGuardRulesFromStore() async throws {
        let client = FountainStoreClient(client: EmbeddedFountainStoreClient())
        let store = ConfigurationStore(client: client, corpusId: "c")
        let yaml = """
        rules:
          "/admin": "root"
        """
        try await store.put("roleguard.yml", data: Data(yaml.utf8))
        let env = [
            "FOUNTAINSTORE_URL": "embedded",
            "FOUNTAINSTORE_API_KEY": "k",
            "DEFAULT_CORPUS_ID": "c"
        ]
        let rules = loadRoleGuardRules(store: store, environment: env)
        XCTAssertEqual(rules["/admin"]?.roles ?? [], ["root"])
    }
