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
#endif
