import XCTest
import SwiftCursesKit

final class SwiftCursesKitIntegrationTests: XCTestCase {
    func testGaugeWidgetProducesRenderCommands() {
        let gaugeScene = Gauge(title: "Bootstrap", value: 0.72)
        let nodes = gaugeScene.makeSceneNodes()
        XCTAssertEqual(nodes.count, 1)

        guard case let .widget(widget) = nodes.first?.kind else {
            XCTFail("Expected Gauge scene to produce a widget node")
            return
        }

        let constraints = LayoutConstraints(maxWidth: 24, maxHeight: 3)
        let measured = widget.measure(in: constraints)
        XCTAssertGreaterThan(measured.width, 0)
        XCTAssertEqual(measured.height, 3)

        var buffer = RenderBuffer()
        widget.render(
            in: LayoutRect(origin: .zero, size: measured),
            buffer: &buffer
        )

        XCTAssertFalse(buffer.commands.isEmpty)
        XCTAssertTrue(
            buffer.commands.contains { $0.text.contains("[") && $0.text.contains("]") },
            "Expected rendered output to include gauge bar"
        )
    }

    func testStatusBarRendersSingleCommand() {
        let status = StatusBar(items: [.label("q: quit"), .label("⌘R: refresh")])
        let nodes = status.makeSceneNodes()
        XCTAssertEqual(nodes.count, 1)

        guard case let .widget(widget) = nodes.first?.kind else {
            XCTFail("Expected StatusBar to produce a widget node")
            return
        }

        var buffer = RenderBuffer()
        widget.render(
            in: LayoutRect(origin: .zero, size: LayoutSize(width: 40, height: 1)),
            buffer: &buffer
        )

        XCTAssertEqual(buffer.commands.count, 1)
        XCTAssertTrue(
            buffer.commands[0].text.contains("q: quit"),
            "Status bar should surface provided labels"
        )
    }
}
