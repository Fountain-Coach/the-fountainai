#if canImport(SwiftUI) && canImport(TeatroRenderAPI)
import SwiftUI
import TeatroRenderAPI

/// SwiftUI view displaying supervisor state, logs and Teatro scene.
public struct ControlPlaneDashboardView: View {
    @ObservedObject var model: ControlPlaneUIModel

    public init(model: ControlPlaneUIModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            List(model.statuses, id: \.name) { status in
                HStack {
                    Text(status.name)
                    Spacer()
                    Circle()
                        .fill(status.healthy ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Button(status.running ? "Stop" : "Start") {
                        model.toggle(service: status.name)
                    }
                    Button("Restart") {
                        model.restart(service: status.name)
                    }
                }
            }
            if !model.svg.isEmpty {
                TeatroPlayerView(svg: model.svg, timeline: model.timeline)
                    .frame(height: 200)
            }
            ScrollView {
                ForEach(model.logs, id: \.self) { line in
                    Text(line)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
    }
}
#else

/// Minimal renderer producing HTML and Markdown output from a ``DashboardModel``.
/// This fallback is used in environments without SwiftUI.
public struct DashboardView {
    public let model: DashboardModel

    public init(model: DashboardModel) {
        self.model = model
    }

    /// Render the model into a very small HTML snippet.
    public func renderHTML() -> String {
        let rows = model.statuses.map { status in
            "<tr><td>\(status.name)</td><td>\(status.running)</td><td>\(status.healthy)</td></tr>"
        }.joined()
        let logs = model.logs.map { "<li>\($0)</li>" }.joined()
        return "<h1>Dashboard</h1><table>\(rows)</table><ul>\(logs)</ul>"
    }

    /// Render the model into a Markdown table with logs as bullet points.
    public func renderMarkdown() -> String {
        var table = "| Service | Running | Healthy |\n|---|---|---|\n"
        table += model.statuses.map { status in
            "| \(status.name) | \(status.running) | \(status.healthy) |"
        }.joined(separator: "\n")
        let logs = model.logs.map { "- \($0)" }.joined(separator: "\n")
        return "# Dashboard\n\(table)\n\(logs)"
    }
}
#endif
