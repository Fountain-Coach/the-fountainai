import XCTest
@testable import FountainAiLauncher

final class ControlPlaneUITests: XCTestCase {
    /// DashboardModel should round-trip through JSON.
    func testDashboardModelCodable() throws {
        let statuses = [ServiceStatus(name: "Echo", running: true, healthy: false)]
        let model = DashboardModel(statuses: statuses, logs: ["Started"])
        let data = try JSONEncoder().encode(model)
        let decoded = try JSONDecoder().decode(DashboardModel.self, from: data)
        XCTAssertEqual(decoded, model)
    }

    /// DashboardView should render model values into HTML and Markdown.
    func testDashboardViewRendering() {
        let statuses = [ServiceStatus(name: "Echo", running: true, healthy: false)]
        let model = DashboardModel(statuses: statuses, logs: ["Started"])
        let view = DashboardView(model: model)

        let html = view.renderHTML()
        let expectedHTML = "<h1>Dashboard</h1><table><tr><td>Echo</td><td>true</td><td>false</td></tr></table><ul><li>Started</li></ul>"
        XCTAssertEqual(html, expectedHTML)

        let markdown = view.renderMarkdown()
        let expectedMarkdown = [
            "# Dashboard",
            "| Service | Running | Healthy |",
            "|---|---|---|",
            "| Echo | true | false |",
            "- Started"
        ].joined(separator: "\n")
        XCTAssertEqual(markdown, expectedMarkdown)
    }
}
