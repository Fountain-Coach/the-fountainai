import XCTest
@testable import OpenAPICurator

private struct SpecFile: Codable {
    let operations: [String]
    let extensions: [String: [String: String]]?
}

private func loadSpec(_ name: String) -> Spec {
    let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")!
    let data = try! Data(contentsOf: url)
    let file = try! JSONDecoder().decode(SpecFile.self, from: data)
    return Spec(operations: file.operations, extensions: file.extensions ?? [:])
}

final class OpenAPICuratorTests: XCTestCase {
    func testRuleApplicationRenamesOperations() {
        let spec = Spec(operations: ["getUser"])
        let rules = Rules(renames: ["getUser": "fetchUser"])
        let result = curate(specs: [spec], rules: rules)
        XCTAssertTrue(result.report.appliedRules.contains("getUser->fetchUser"))
        XCTAssertEqual(result.spec.operations, ["fetchUser"])
    }

    func testCollisionResolverAddsSuffix() {
        let spec1 = loadSpec("collidingA")
        let spec2 = loadSpec("collidingB")
        let expected = loadSpec("expectedCurated")
        let result = curate(specs: [spec1, spec2], rules: Rules())
        XCTAssertEqual(result.report.collisions, ["op"])
        XCTAssertEqual(result.spec.operations, expected.operations)
    }

    func testDenylistRemoval() {
        let spec = Spec(operations: ["keep", "drop"])
        let rules = Rules(denylist: ["drop"])
        let result = curate(specs: [spec], rules: rules)
        XCTAssertEqual(result.spec.operations, ["keep"])
        XCTAssertTrue(result.report.diff.contains("drop"))
    }

    func testAllowlistEnforcement() {
        let spec = Spec(operations: ["keep", "drop"])
        let rules = Rules(allowlist: ["keep"])
        let result = curate(specs: [spec], rules: rules)
        XCTAssertEqual(result.spec.operations, ["keep"])
    }

    func testDiffGeneration() {
        let spec = Spec(operations: ["keep", "remove"])
        let rules = Rules(denylist: ["remove"])
        let result = curate(specs: [spec], rules: rules)
        XCTAssertEqual(result.report.diff, ["remove"])
    }

    func testSubmissionCallsToolsFactory() {
        let spec = Spec(operations: ["op"])
        var submitted: OpenAPI?
        _ = OpenAPICuratorKit.run(specs: [spec], submit: true, submitter: { api in
            submitted = api
        })
        XCTAssertEqual(submitted?.operations, ["op"])
    }

    func testFountainExtensionsRecognized() {
        let spec = Spec(operations: ["op"], extensions: ["op": ["x-fountain.visibility": "public"]])
        let result = curate(specs: [spec], rules: Rules())
        XCTAssertTrue(result.report.appliedRules.contains("x-fountain.visibility=public"))
    }

    func testTruthTableOutput() {
        let spec = Spec(operations: ["op"], extensions: ["op": [
            "x-fountain.visibility": "internal",
            "x-fountain.reason": "example",
            "x-fountain.allow-as-tool": "false"
        ]])
        let result = curate(specs: [spec], rules: Rules())
        let entry = result.report.truthTable["op"]
        XCTAssertEqual(entry?.visibility, "internal")
        XCTAssertEqual(entry?.reason, "example")
        XCTAssertEqual(entry?.allowAsTool, false)
    }

    func testReviewerHookInvoked() {
        let spec = Spec(operations: ["op"])
        var reviewed = false
        _ = OpenAPICuratorKit.run(specs: [spec], reviewer: { _, _ in reviewed = true })
        XCTAssertTrue(reviewed)
    }

    func testPerformanceLargeMerge() {
        let specs = (0..<1000).map { Spec(operations: ["op\($0)"]) }
        let start = Date()
        _ = curate(specs: specs, rules: Rules())
        let duration = Date().timeIntervalSince(start)
        XCTAssertLessThan(duration, 1.0)
    }
}
