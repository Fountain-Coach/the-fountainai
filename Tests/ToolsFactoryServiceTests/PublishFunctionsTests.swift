import XCTest
@testable import ToolsFactoryService
@testable import FountainStoreClient

final class PublishFunctionsTests: XCTestCase {
    func testPublishFunctionsUpsertsIntoPersistence() async throws {
        let manifest = ToolManifest(
            image: .init(name: "img", tarball: "t", sha256: "s", qcow2: "q", qcow2_sha256: "qs"),
            tools: [:],
            operations: ["op1", "op2"]
        )
        let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
        await svc.ensureCollections()
        try await publishFunctions(manifest: manifest, corpusId: "tools", service: svc)
        let (total, list) = try await svc.listFunctions(corpusId: "tools")
        XCTAssertEqual(total, 2)
        XCTAssertEqual(Set(list.map { $0.functionId }), Set(["op1","op2"]))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

