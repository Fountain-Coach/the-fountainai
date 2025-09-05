import XCTest
@testable import openapi_curator_service
import FountainStoreClient

final class ConfigurationStoreTests: XCTestCase {
    func testLoadCuratorRulesFromStore() async throws {
        let client = FountainStoreClient(client: EmbeddedFountainStoreClient())
        let store = ConfigurationStore(client: client, corpusId: "c")
        let yaml = """
        renames:
          old: new
        """
        try await store.put("curator.yml", data: Data(yaml.utf8))
        let env = [
            "FOUNTAINSTORE_URL": "embedded",
            "FOUNTAINSTORE_API_KEY": "k",
            "DEFAULT_CORPUS_ID": "c"
        ]
        let rules = loadCuratorRules(environment: env, store: store)
        XCTAssertEqual(rules.renames["old"], "new")
    }
}
