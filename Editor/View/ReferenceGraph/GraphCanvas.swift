//
//  GraphCanvas.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Combine
import DataStoreKit
import DataStoreSupport
import SwiftData
import SwiftUI

extension String {
    nonisolated static var edgeGlimmerInverted: Self {
        "edge-glimmer-inverted"
    }
    
    nonisolated static var edgeArrowheadsEnabled: Self {
        "edge-arrowheads-enabled"
    }
    
    nonisolated static var edgeArrowheadInset: Self {
        "edge-arrowheads-inset"
    }
}

struct GraphCanvas: View {
    @Environment(Graph.self) private var view
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var panBaseOffset: CGSize = .zero
    @State private var isPanning: Bool = false
    @State private var zoomBase: CGFloat = 1.0
    @State private var isZooming: Bool = false
    @State private var glimmerTime: TimeInterval = 0
    @State private var timer: Publishers.Autoconnect<Timer.TimerPublisher> = Timer.publish(
        every: 1/60,
        on: .main,
        in: .common
    ).autoconnect()
    
    @AppStorage(.edgeArrowheadInset)
    private var edgeArrowheadInset: Double = 30
    
    @AppStorage(.edgeArrowheadsEnabled)
    private var edgeArrowheadsEnabled: Bool = true
    
    @AppStorage(.edgeGlimmerInverted)
    private var edgeGlimmerInverted: Bool = true
    
    enum EdgeArrowheadMode: String, CaseIterable, Identifiable {
        case none
        case target
        case both
        
        var id: String { rawValue }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Canvas(rendersAsynchronously: true) { context, size in
                    for edge in view.edges.values {
                        guard let owner = self.view.nodes[edge.owner],
                              let target = self.view.nodes[edge.target] else {
                            continue
                        }
                        let ownerPoint = self.view.worldToScreen(owner.position, in: size)
                        let targetPoint = self.view.worldToScreen(target.position, in: size)
                        var path = Path()
                        path.move(to: ownerPoint)
                        path.addLine(to: targetPoint)
                        let highlighted =
                        view.selection.contains(edge.owner) || view.selection.contains(edge.target)
                        let baseColor = self.view.plugins.style.edgeStroke(
                            for: edge,
                            highlighted: highlighted
                        )
                        let baseWidth = self.view.plugins.style.edgeLineWidth(
                            for: edge,
                            highlighted: highlighted
                        )
                        context.stroke(
                            path,
                            with: .color(baseColor),
                            style: StrokeStyle(
                                lineWidth: baseWidth,
                                lineCap: .round,
                                lineJoin: .round,
                                dash: view.plugins.style.edgeDash(for: edge) ?? [],
                                dashPhase: 0
                            )
                        )
                        let seed = CGFloat(UInt(bitPattern: edge.id.hashValue) % 10_000) / 10_000
                        drawEdgeGlimmer(
                            context: context,
                            from: ownerPoint,
                            to: targetPoint,
                            baseColor: baseColor,
                            baseWidth: baseWidth,
                            time: glimmerTime,
                            seed: seed,
                            enabled: highlighted,
                            inverted: edgeGlimmerInverted
                        )
                        if edgeArrowheadsEnabled {
                            let angle = atan2(
                                targetPoint.y - ownerPoint.y,
                                targetPoint.x - ownerPoint.x
                            )
                            let arrowLength: CGFloat = 8
                            let arrowWidth: CGFloat = 5
                            let inset = CGFloat(edgeArrowheadInset)
                            let tip = CGPoint(
                                x: targetPoint.x - inset * cos(angle),
                                y: targetPoint.y - inset * sin(angle)
                            )
                            var arrow = Path()
                            arrow.move(to: tip)
                            arrow.addLine(to: CGPoint(
                                x: tip.x - arrowLength * cos(angle) + arrowWidth * sin(angle),
                                y: tip.y - arrowLength * sin(angle) - arrowWidth * cos(angle)
                            ))
                            arrow.addLine(to: CGPoint(
                                x: tip.x - arrowLength * cos(angle) - arrowWidth * sin(angle),
                                y: tip.y - arrowLength * sin(angle) + arrowWidth * cos(angle)
                            ))
                            arrow.closeSubpath()
                            context.fill(
                                arrow,
                                with: .color(view.plugins.style.edgeStroke(
                                    for: edge,
                                    highlighted: highlighted
                                ))
                            )
                        }
                    }
                }
                .drawingGroup()
                ForEach(Array(view.edges.values)) { edge in
                    if let a = self.view.nodes[edge.owner],
                       let b = self.view.nodes[edge.target] {
                        let mid = CGPoint(
                            x: (a.position.x + b.position.x)/2,
                            y: (a.position.y + b.position.y)/2
                        )
                        let distance = hypot(
                            b.position.x - a.position.x,
                            b.position.y - a.position.y
                        )
                        if distance > view.configurations.labelEdgeThreshold {
                            Text(edge.property)
                                .font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(view.plugins.style.edgeLabelBackground(for: edge))
                                .clipShape(Capsule())
                                .position(view.worldToScreen(mid, in: geometry.size))
                        }
                    }
                }
                ForEach(Array(view.nodes.values), id: \.id) { node in
                    NodeBubble(node: node)
                        .accessibilityLabel(Text(view.plugins.label.title(for: node.id)))
                        .modifier(NodePositionModifier(size: geometry.size))
                        .environment(node)
                }
            }
            .toolbar {
                ToolbarItem {
                    Menu("Options", systemImage: "ellipsis") {
                        Toggle("Show Arrowheads", isOn: $edgeArrowheadsEnabled)
                        Slider(value: $edgeArrowheadInset, in: 10...80, step: 1) {
                            Text("Arrowhead Inset: \(Int(edgeArrowheadInset))")
                        }
                    }
                }
                ToolbarItem {
                    Button {
                        withAnimation(.snappy) { view.zoom *= 1.1 }
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                    }
                }
                ToolbarItem {
                    Button {
                        withAnimation(.snappy) { view.zoom /= 1.1 }
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                    }
                }
                ToolbarItem {
                    Button {
                        withAnimation(.snappy) {
                            view.zoom = 1; view.offset = .zero
                        }
                    } label: {
                        Image(systemName: "gobackward")
                    }
                }
                if horizontalSizeClass == .regular {
                    ToolbarItem {
                        @Bindable var view = self.view
                        GraphFilterTextField(text: $view.searchText)
                            .frame(minWidth: 50, maxWidth: 250)
                    }
                }
            }
            .gesture(panAndZoomGesture(in: geometry.size))
            .onReceive(timer) { _ in
                glimmerTime = Date().timeIntervalSinceReferenceDate
                view.stepLayout(size: geometry.size)
            }
        }
    }
    
    private func drawEdgeGlimmer(
        context: GraphicsContext,
        from a: CGPoint,
        to b: CGPoint,
        baseColor: Color,
        baseWidth: CGFloat,
        time: TimeInterval,
        seed: CGFloat,
        enabled: Bool,
        inverted: Bool
    ) {
        guard enabled else { return }
        let time = CGFloat(time)
        let direction: CGFloat = inverted ? -1 : 1
        let raw = (seed + direction * time * 0.55).truncatingRemainder(dividingBy: 1)
        let progress = raw < 0 ? raw + 1 : raw
        let beamLength: CGFloat = 0.22
        let tail = max(0, progress - beamLength)
        let head = progress
        let start = CGPoint(x: a.x + (b.x - a.x) * tail, y: a.y + (b.y - a.y) * tail)
        let end = CGPoint(x: a.x + (b.x - a.x) * head, y: a.y + (b.y - a.y) * head)
        var beam = Path()
        beam.move(to: start)
        beam.addLine(to: end)
        var glow = context
        glow.blendMode = .plusLighter
        glow.stroke(
            beam,
            with: .color(baseColor.opacity(0.20)),
            style: .init(lineWidth: max(2, baseWidth * 3.5), lineCap: .round)
        )
        glow.stroke(
            beam,
            with: .color(.white.opacity(0.90)),
            style: .init(lineWidth: max(1, baseWidth * 1.6), lineCap: .round)
        )
        let dash: [CGFloat] = [10, 16]
        let dashTotal = dash.reduce(0, +)
        let dashPhase =
        (inverted ? 1 : -1) * (time * 140).truncatingRemainder(dividingBy: dashTotal)
        glow.stroke(
            Path { path in
                path.move(to: a)
                path.addLine(to: b)
            },
            with: .color(.white.opacity(0.12)),
            style: .init(
                lineWidth: baseWidth,
                lineCap: .round,
                dash: dash,
                dashPhase: dashPhase
            )
        )
    }
    
    private func panAndZoomGesture(in size: CGSize) -> some Gesture {
        SimultaneousGesture(
            DragGesture()
                .onChanged { value in
                    if !isPanning {
                        self.panBaseOffset = view.offset
                        self.isPanning = true
                    }
                    self.view.offset = CGSize(
                        width: panBaseOffset.width + value.translation.width,
                        height: panBaseOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    self.isPanning = false
                },
            MagnificationGesture()
                .onChanged { scale in
                    if !isZooming {
                        self.zoomBase = view.zoom
                        self.isZooming = true
                    }
                    self.view.zoom = max(0.2, min(4.0, zoomBase * scale))
                }
                .onEnded { _ in
                    self.isZooming = false
                }
        )
    }
    
    struct GraphFilterTextField: View {
        @Binding var text: String
        
        var body: some View {
            TextField("Filter...", text: $text)
                .textFieldStyle(.plain)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
                .overlay(alignment: .trailing) {
                    if !text.isEmpty {
                        Button {
                            self.text = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                    }
                }
        }
    }
    
    struct NodePositionModifier: ViewModifier {
        @Environment(Graph.self) private var view
        @Environment(Graph.Node.self) private var node
        var size: CGSize
        
        func body(content: Content) -> some View {
            content
                .position(view.worldToScreen(node.position, in: size))
                .gesture(dragGesture(for: node, in: size))
                .simultaneousGesture(TapGesture(count: 1).onEnded { _ in
                    _ = view.plugins.interaction.didSelect(node: node.id)
                    withAnimation {
                        view.toggleSelection(node.id)
                    }
                })
        }
        
        private func dragGesture(for node: Graph.Node, in size: CGSize) -> some Gesture {
            DragGesture()
                .onChanged { value in
                    let world = self.view.screenToWorld(value.location, in: size)
                    if let nodeState = self.view.nodes[node.id] {
                        nodeState.position = world
                        nodeState.velocity = .zero
                        nodeState.isFixed = true
                        view.nodes[node.id] = nodeState
                    }
                }
                .onEnded { _ in }
        }
    }
    
    struct NodeBubble: View {
        @Environment(Graph.self) private var view
        @Environment(\.colorScheme) private var colorScheme
        @State private var title: String = ""
        @State private var isSelected: Bool = false
        @State private var isHighlighted: Bool = false
        @State private var diameter: CGFloat = .zero
        @State var node: Graph.Node
        
        @AppStorage(.nodeLabelPlacement)
        private var placement: NodeLabelPlacement = .innerEdge
        
        var body: some View {
            CircleContainer {
                EntityNodeIcon()
                EntityNodeTitle(placement: placement, diameter: diameter)
            }
            .scaleEffect((node.isHighlighted && !node.isSelected) ? 0.9 : 1.0)
            .animation(
                .spring(duration: 0.15, bounce: 0.3, blendDuration: 0.8),
                value: node.isHighlighted
            )
            .onChange(of: view.selection.contains(node.id), initial: true) { _, newValue in
                Task(priority: .userInitiated) { self.node.isSelected = newValue }
            }
            .onChange(of: view.isHighlighted(node.id), initial: true) { _, newValue in
                Task(priority: .utility) { self.node.isHighlighted = newValue }
            }
            .onChange(of: node.id, initial: true) { _, newValue in
                Task { @DatabaseActor in
                    if let _ = await self.view.nodes[newValue] {
                        let fill = await view.plugins.style.nodeFill(
                            for: node.id,
                            selected: node.isSelected,
                            highlighted: node.isHighlighted
                        )
                        let stroke = await self.view.plugins.style.nodeStroke(
                            for: node.id,
                            selected: node.isSelected,
                            highlighted: node.isHighlighted
                        )
                        await MainActor.run {
                            self.node.fill = AnyShapeStyle(fill)
                            self.node.stroke = AnyShapeStyle(stroke)
                        }
                    }
                }
            }
            .frame(width: diameter, height: diameter)
            .onChange(of: node.id, initial: true) { _, newValue in
                Task(priority: .utility) { @concurrent in
                    let radius = await view.plugins.style.nodeRadius(for: newValue)
                    await MainActor.run {
                        withAnimation(.spring()) { self.diameter = max(48, radius * 4) }
                    }
                }
            }
            .contextMenu {
                ForEach(view.plugins.interaction.contextMenu(for: node.id)) { item in
                    Button(action: item.action) {
                        Label(item.title, systemImage: item.systemImage ?? "circle")
                    }
                }
            }
        }
    }
    
    struct CircleContainer<Content>: View where Content: View {
        @Environment(Graph.self) private var view
        @Environment(Graph.Node.self) private var node
        @ViewBuilder var content: Content
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(
                        AnyShapeStyle(view.plugins.style.nodeFill(
                            for: node.id,
                            selected: node.isSelected,
                            highlighted: node.isHighlighted
                        ))
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                AnyShapeStyle(view.plugins.style.nodeStroke(
                                    for: node.id,
                                    selected: node.isSelected,
                                    highlighted: node.isHighlighted
                                )),
                                lineWidth: node.isSelected ? 5.0 : 2.5
                            )
                            .shadow(radius: (node.isHighlighted && !node.isSelected) ? 15 : 0)
                    )
                    .overlay(
                        Circle()
                            .inset(by: -(((node.isHighlighted && !node.isSelected) ? 8 : 0) + 2 / 2))
                            .strokeBorder(
                                (node.isHighlighted && !node.isSelected) ? .blue : .white,
                                style: .init(
                                    lineWidth: (node.isHighlighted && !node.isSelected) ? 3.0 : 1.5,
                                    lineCap: .round,
                                    lineJoin: .round,
                                    dash: (node.isHighlighted && !node.isSelected) ? [4, 6] : []
                                )
                            )
                            .animation(
                                .spring(duration: 0.15, bounce: 0.5),
                                value: (node.isHighlighted && !node.isSelected)
                            )
                            .allowsHitTesting(false)
                    )
                    .overlay(
                        GlimmerRing(
                            active: node.isHighlighted && !node.isSelected,
                            color: .blue,
                            inset: -(((node.isHighlighted && !node.isSelected) ? 8 : 0) + 2 / 2),
                            lineWidth: 3
                        )
                    )
                content
            }
        }
    }
    
    struct EntityNodeTitle: View {
        @Environment(Graph.self) private var view
        @Environment(Graph.Node.self) private var node
        @State private var title: String = ""
        var placement: NodeLabelPlacement
        var diameter: CGFloat
        
        var body: some View {
            if placement != .center {
                let inset: CGFloat = (placement == .outerEdge) ? 4 : 12
                let ringRadius = diameter / 2 - inset
                let fontSize = max(10, diameter * 0.18)
                CircularText(
                    text: title,
                    radius: ringRadius,
                    arcDegrees: 225,
                    fontSize: fontSize
                )
                .onChange(of: node.id, initial: true) { _, newValue in
                    Task { @concurrent in
                        let newValue = await view.plugins.label.title(for: newValue)
                        await MainActor.run { self.title = newValue }
                    }
                }
                .foregroundStyle(!node.isSelected && !node.isHighlighted ? .white : .black)
                .fontWeight(.black)
                .textCase(.uppercase)
            }
        }
    }
    
    struct EntityNodeIcon: View {
        @DatabaseActor @Environment(Graph.self) private var view
        @Environment(Graph.Node.self) private var node
        
        var body: some View {
            Image(systemName: node.systemImage ?? "questionmark")
                .imageScale(.medium)
                .padding(4)
                .background(.ultraThinMaterial.opacity(node.isSelected ? 1 : 0), in: Circle())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .overlay(alignment: .bottom) {
                    if let subtitle = self.node.subtitle {
                        Text(subtitle)
                            .font(.caption2.weight(.black))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .safeAreaPadding(.vertical, 8)
                    }
                }
                .foregroundStyle(!node.isSelected && !node.isHighlighted ? .white : .black)
                .onChange(of: node.id, initial: true) { _, newValue in
                    Task { @concurrent in
                        let subtitle = await view.plugins.label.subtitle(for: newValue)
                        let systemImage = await view.plugins.label.systemImage(for: newValue)
                        await MainActor.run {
                            self.node.subtitle = subtitle
                            self.node.systemImage = systemImage
                        }
                    }
                }
        }
    }
}

struct GlimmerRing: View {
    @State private var phase: CGFloat = 0
    var active: Bool
    var color: Color
    var inset: CGFloat
    var lineWidth: CGFloat
    
    var body: some View {
        Circle()
            .inset(by: inset)
            .stroke(
                AngularGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0.00),
                        .init(color: color.opacity(0.18), location: 0.35),
                        .init(color: .white.opacity(0.95), location: 0.50),
                        .init(color: color.opacity(0.18), location: 0.65),
                        .init(color: .clear, location: 1.00)
                    ]),
                    center: .center
                ),
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round,
                    dash: [10, 18],
                    dashPhase: -phase * 1.6
                )
            )
            .rotationEffect(.degrees(phase))
            .blendMode(.plusLighter)
            .blur(radius: lineWidth * 0.6)
            .opacity(active ? 1 : 0)
            .allowsHitTesting(false)
            .task(id: active) {
                guard active else { return }
                self.phase = 0
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    self.phase = 360
                }
            }
    }
}
