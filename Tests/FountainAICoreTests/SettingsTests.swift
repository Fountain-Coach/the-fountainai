import XCTest
@testable import FountainAICore

final class SettingsTests: XCTestCase {
    func testValidationCatchesMissingFields() throws {
        let s = AppSettings(provider: .customHTTP, modelName: "", baseURL: nil, apiKeyRef: nil, persist: .embedded(path: ""), corpusId: "")
        let issues = s.validate()
        XCTAssertTrue(issues.contains(where: { $0.contains("Model name") }))
        XCTAssertTrue(issues.contains(where: { $0.contains("Base URL") }))
        XCTAssertTrue(issues.contains(where: { $0.contains("Embedded path") }))
        XCTAssertTrue(issues.contains(where: { $0.contains("Corpus ID") }))
    }

    func testSaveAndLoadRoundtrip() throws {
        let defaults = UserDefaults(suiteName: "SettingsTests")!
        defaults.removePersistentDomain(forName: "SettingsTests")
        let store = DefaultSettingsStore(defaults: defaults)
        var s = AppSettings()
        s.provider = .openai
        s.modelName = "gpt-4o-mini"
        s.apiKeyRef = "openai-key"
        s.persist = .remote(url: "http://persist.local", apiKeyRef: "persist-key")
        s.corpusId = "gui"
        try store.save(s)
        let loaded = try store.load()
        XCTAssertEqual(loaded, s)
    }
}
