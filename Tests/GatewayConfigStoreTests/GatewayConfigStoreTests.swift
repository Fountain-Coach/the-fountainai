import XCTest
@testable import gateway_server
import FountainStoreClient

final class GatewayConfigStoreTestsCase: XCTestCase {
    func testLoadGatewayConfigFromStore() async throws {
        let client = FountainStoreClient(client: EmbeddedFountainStoreClient())
        let store = ConfigurationStore(client: client, corpusId: "test")
        try await store.put("gateway.yml", data: Data("rateLimitPerMinute: 7".utf8))
        let env = [
            "FOUNTAINSTORE_URL": "embedded",
            "FOUNTAINSTORE_API_KEY": "key",
            "DEFAULT_CORPUS_ID": "test"
        ]
        let cfg = try loadGatewayConfig(store: store, environment: env)
        XCTAssertEqual(cfg.rateLimitPerMinute, 7)
    }
}
