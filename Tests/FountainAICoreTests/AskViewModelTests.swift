import XCTest
@testable import FountainAICore

final class AskViewModelTests: XCTestCase {
    func testAskWithURLUsesContextThenAnswers() async throws {
        let llm = MockLLM(answer: "This is the answer.")
        let browser = MockBrowser(title: "Doc Title", summary: "Key points from the page.")
        let vm = AskViewModel(llm: llm, browser: browser)
        await vm.ask(question: "Summarize it", url: "https://example.com", model: "test", corpusId: "gui")
        let s = await vm.state
        XCTAssertEqual(s, .done)
        let ans = await vm.answer
        XCTAssertEqual(ans, "This is the answer.")
        let src = await vm.sourceURL
        XCTAssertEqual(src, "https://example.com")
        // Verify the LLM saw a system context first
        let msgs1 = await llm.snapshot()
        XCTAssertEqual(msgs1.first?.role, .system)
        XCTAssertTrue(msgs1.first?.content.contains("Key points") == true)
    }

    func testAskWithoutURLJustAnswers() async throws {
        let llm = MockLLM(answer: "Plain answer.")
        let browser = MockBrowser()
        let persist = MockPersistence()
        let vm = AskViewModel(llm: llm, browser: browser, persistence: persist)
        await vm.ask(question: "Hello", url: nil, model: "test", corpusId: nil)
        let s = await vm.state
        XCTAssertEqual(s, .done)
        let answer = await vm.answer
        XCTAssertEqual(answer, "Plain answer.")
        let msgs = await llm.snapshot()
        XCTAssertEqual(msgs.count, 1)
        XCTAssertEqual(msgs.first?.role, .user)
        let savedCount = await persist.count()
        XCTAssertEqual(savedCount, 1)
    }
}

// MARK: - Mocks

final actor MockLLM: LLMService {
    let answer: String
    private(set) var messages: [ChatMessage] = []
    init(answer: String) { self.answer = answer }
    func chat(model: String, messages: [ChatMessage]) async throws -> String {
        self.messages = messages
        return answer
    }
    func snapshot() -> [ChatMessage] { messages }
}

final actor MockBrowser: BrowserService {
    let title: String?
    let summary: String?
    init(title: String? = nil, summary: String? = nil) { self.title = title; self.summary = summary }
    func analyze(url: String, corpusId: String?) async throws -> (title: String?, summary: String?) {
        return (title, summary)
    }
}

final actor MockPersistence: PersistenceService {
    var saved: [(q:String,u:String?,a:String,su:String?,st:String?,c:String?)] = []
    func save(question: String, url: String?, answer: String, sourceURL: String?, sourceTitle: String?, corpusId: String?) async throws {
        saved.append((question,url,answer,sourceURL,sourceTitle,corpusId))
    }
    func count() -> Int { saved.count }
}
