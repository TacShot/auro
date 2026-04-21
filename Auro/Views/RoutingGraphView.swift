import SwiftUI

// MARK: - RoutingGraphView
//
// Animated canvas showing source nodes (apps/input devices) on the left,
// destination nodes (output devices) on the right, and bezier connections.

struct RoutingGraphView: View {
    @EnvironmentObject var engine: AudioEngine
    @State private var dragging: DragState? = nil
    @State private var phase: CGFloat = 0

    // MARK: Layout helpers
    private struct NodeInfo: Identifiable {
        var id: String
        var label: String
        var isSource: Bool
        var isActive: Bool
        var level: Float
        var iconName: String
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1/60)) { timeline in
                Canvas { ctx, size in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    drawGraph(ctx: ctx, size: size, elapsed: elapsed)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        handleDrag(value, in: geo.size)
                    }
                    .onEnded { _ in
                        finishDrag(in: geo.size)
                    }
            )
            .overlay(alignment: .bottomTrailing) {
                addRouteHint
                    .padding(12)
            }
        }
        .background(Color.black.opacity(0.02))
    }

    // MARK: Drawing

    private func drawGraph(ctx: GraphicsContext, size: CGSize, elapsed: Double) {
        let sources = sourceNodes()
        let dests   = destNodes()

        // Calculate positions
        let leftX  = size.width  * 0.22
        let rightX = size.width  * 0.78
        let nodeH: CGFloat = 52
        let nodeW: CGFloat = 160

        func yPos(index: Int, count: Int, height: CGFloat) -> CGFloat {
            guard count > 0 else { return height / 2 }
            let spacing = height / CGFloat(count + 1)
            return spacing * CGFloat(index + 1)
        }

        // Draw connections first (behind nodes)
        for route in engine.routes {
            guard let srcIdx = sources.firstIndex(where: { $0.id == route.sourceID }),
                  let dstIdx = dests.firstIndex(where: { $0.id == route.destinationUID })
            else { continue }

            let srcY = yPos(index: srcIdx, count: sources.count, height: size.height)
            let dstY = yPos(index: dstIdx, count: dests.count,   height: size.height)

            let p0 = CGPoint(x: leftX  + nodeW / 2, y: srcY)
            let p3 = CGPoint(x: rightX - nodeW / 2, y: dstY)
            let cp1 = CGPoint(x: p0.x + (p3.x - p0.x) * 0.4, y: p0.y)
            let cp2 = CGPoint(x: p3.x - (p3.x - p0.x) * 0.4, y: p3.y)

            var path = Path()
            path.move(to: p0)
            path.addCurve(to: p3, control1: cp1, control2: cp2)

            let color: Color = route.isActive ? .cyan : .gray
            let dashPhase = CGFloat(elapsed.truncatingRemainder(dividingBy: 1.0)) * 20

            ctx.stroke(
                path,
                with: .color(color.opacity(0.25)),
                style: StrokeStyle(lineWidth: 3)
            )
            ctx.stroke(
                path,
                with: .color(color.opacity(0.7)),
                style: StrokeStyle(lineWidth: 1.5, dash: [8, 6], dashPhase: dashPhase)
            )
        }

        // Draw source nodes (left)
        for (i, node) in sources.enumerated() {
            let y = yPos(index: i, count: sources.count, height: size.height)
            let rect = CGRect(x: leftX - nodeW / 2, y: y - nodeH / 2, width: nodeW, height: nodeH)
            drawNode(ctx: ctx, rect: rect, node: node, elapsed: elapsed, isLeft: true)
        }

        // Draw destination nodes (right)
        for (i, node) in dests.enumerated() {
            let y = yPos(index: i, count: dests.count, height: size.height)
            let rect = CGRect(x: rightX - nodeW / 2, y: y - nodeH / 2, width: nodeW, height: nodeH)
            drawNode(ctx: ctx, rect: rect, node: node, elapsed: elapsed, isLeft: false)
        }

        // Draw drag-in-progress line
        if let drag = dragging {
            var linePath = Path()
            linePath.move(to: drag.startPoint)
            linePath.addLine(to: drag.currentPoint)
            ctx.stroke(linePath, with: .color(.yellow.opacity(0.8)),
                       style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
        }
    }

    private func drawNode(ctx: GraphicsContext, rect: CGRect, node: NodeInfo, elapsed: Double, isLeft: Bool) {
        let pulse = node.isActive
            ? 0.85 + 0.15 * CGFloat(sin(elapsed * 3 + Double(node.id.hashValue) * 0.01))
            : 0.6

        let rr = RoundedRectangle(cornerRadius: 10)
        let rrPath = rr.path(in: rect)

        // Shadow glow
        if node.isActive {
            ctx.fill(rrPath, with: .color(Color.cyan.opacity(0.12 * pulse)))
        }

        // Background
        ctx.fill(rrPath, with: .color(Color(.windowBackgroundColor).opacity(0.75)))

        // Border
        ctx.stroke(rrPath, with: .color(node.isActive ? Color.cyan.opacity(pulse) : Color.gray.opacity(0.35)),
                   lineWidth: 1.5)

        // Icon
        let iconRect = CGRect(x: rect.minX + 10, y: rect.midY - 11, width: 22, height: 22)
        ctx.draw(
            Text(Image(systemName: node.iconName))
                .font(.system(size: 14))
                .foregroundColor(node.isActive ? .cyan : .secondary),
            in: iconRect
        )

        // Label
        let labelRect = CGRect(x: rect.minX + 38, y: rect.midY - 11, width: rect.width - 48, height: 22)
        ctx.draw(
            Text(node.label)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .foregroundColor(.primary),
            in: labelRect
        )

        // Level dot
        if node.isActive {
            let dotX: CGFloat = isLeft ? rect.maxX - 8 : rect.minX + 8
            let dot = Path(ellipseIn: CGRect(x: dotX - 4, y: rect.midY - 4, width: 8, height: 8))
            let g = CGFloat(node.level)
            let dotColor = g > 0.8 ? Color.red : g > 0.5 ? Color.yellow : Color.green
            ctx.fill(dot, with: .color(dotColor.opacity(pulse)))
        }
    }

    // MARK: Data helpers

    private func sourceNodes() -> [NodeInfo] {
        var nodes: [NodeInfo] = []
        for app in engine.apps {
            nodes.append(NodeInfo(
                id: app.bundleID,
                label: app.name,
                isSource: true,
                isActive: !app.isMuted && app.peakLevel > 0.05,
                level: app.peakLevel,
                iconName: "app.fill"
            ))
        }
        for dev in engine.inputDevices {
            nodes.append(NodeInfo(
                id: dev.uid,
                label: dev.displayName,
                isSource: true,
                isActive: !dev.isMuted,
                level: 0.3,
                iconName: "mic.fill"
            ))
        }
        return nodes
    }

    private func destNodes() -> [NodeInfo] {
        engine.outputDevices.map { dev in
            NodeInfo(
                id: dev.uid,
                label: dev.displayName,
                isSource: false,
                isActive: !dev.isMuted,
                level: 0.5,
                iconName: "speaker.wave.2.fill"
            )
        }
    }

    // MARK: Drag to route

    private struct DragState {
        var startPoint: CGPoint
        var currentPoint: CGPoint
        var sourceID: String?
    }

    private func handleDrag(_ value: DragGesture.Value, in size: CGSize) {
        if dragging == nil {
            dragging = DragState(startPoint: value.startLocation,
                                 currentPoint: value.location,
                                 sourceID: nil)
        } else {
            dragging?.currentPoint = value.location
        }
    }

    private func finishDrag(in size: CGSize) {
        dragging = nil
    }

    // MARK: Hint overlay

    private var addRouteHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.branch")
            Text("Drag from source to output to create a route")
                .font(.caption2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(.secondary)
    }
}

#Preview {
    RoutingGraphView()
        .environmentObject(AudioEngine.shared)
        .frame(width: 800, height: 500)
}
