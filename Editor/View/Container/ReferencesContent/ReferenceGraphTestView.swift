//
//  ReferenceGraphTestView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import Observation
import SwiftData
import SwiftUI
import Logging

#if canImport(Shared)
import Shared
#endif

#Preview(traits: .defaultData) {
    NavigationStack {
        ReferenceGraphTestView()
    }
}

extension String {
    nonisolated static var referenceGraphAutoRun: Self {
        "reference-graph-auto-run"
    }
}

struct ReferenceGraphTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.schema) private var schema
    @State private var harness: Harness = .init()
    @State private var isPresented: Bool = true
    @AppStorage(.referenceGraphAutoRun) private var autoRun: Bool = true
    
    var body: some View {
        VStack {
            List {
                Section("Source") {
                    Button("Reload Graph") {
                        harness.reload(modelContext: modelContext, schema: schema)
                        if autoRun { self.isPresented = true }
                    }
                }
                Section("Controls") {
                    TextField("Filter nodes...", text: $harness.filterText)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                    Toggle("Show Labels", isOn: $harness.showLabels)
                    Toggle("Highlight Selection", isOn: $harness.shouldHighlight)
                    Toggle("Fetch Limit", isOn: Binding(
                        get: { harness.fetchLimit != nil },
                        set: { self.harness.fetchLimit = $0 ? 10 : nil }
                    ))
                    if let fetchLimit = self.harness.fetchLimit {
                        Stepper(
                            "Per Model Type: \(fetchLimit)",
                            value: Binding(
                                get: { harness.fetchLimit ?? 10 },
                                set: { self.harness.fetchLimit = $0 }
                            ),
                            in: 10...1000,
                            step: 10
                        )
                    }
                }
                Section("Selection") {
                    Picker("Property", selection: $harness.property) {
                        Text("All").tag("")
                        ForEach(harness.relationshipNames, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                }
            }
        }
        .toolbar {
            Toggle("Auto Run", isOn: $autoRun)
            Toggle("Result", isOn: $isPresented)
        }
        .sheet(isPresented: $isPresented) {
            Panel(isPresented: $isPresented)
        }
        .task { harness.reload(modelContext: modelContext, schema: schema) }
        .environment(harness)
    }
    
    struct Panel: View {
        @Environment(Harness.self) private var harness
        @Environment(\.modelContext) private var modelContext
        @Environment(\.schema) private var schema
        @AppStorage(.referenceGraphAutoRun) private var autoRun: Bool = true
        @State private var showSlider: Bool = false
        @State private var detent: PresentationDetent = .medium
        @Binding var isPresented: Bool
        
        var body: some View {
            @Bindable var harness = self.harness
            NavigationStack {
                VStack(spacing: 12) {
                    ScrollView {
                        if showSlider,
                           harness.snapshot.totalOwners + harness.snapshot.totalTargets > 0 {
                            GroupBox("Limit Nodes: \(harness.trimNodeLimit)") {
                                Slider(
                                    value: Binding(
                                        get: { Double(harness.trimNodeLimit) },
                                        set: { self.harness.trimNodeLimit = Int($0.rounded()) }
                                    ),
                                    in: 10...100,
                                    step: 5,
                                    onEditingChanged: { isEditing in
                                        if !isEditing { harness.trim() }
                                    }
                                )
                            }
                            .transition(.move(edge: .top).combined(with: .blurReplace))
                        }
                        HStack(spacing: 12) {
                            StatChip(title: "Owners", value: "\(harness.snapshot.totalOwners)")
                            StatChip(title: "Targets", value: "\(harness.snapshot.totalTargets)")
                            StatChip(title: "Edges", value: "\(harness.snapshot.totalEdges)")
                        }
                        .contentTransition(.numericText(countsDown: false))
                        .animation(.spring, value: harness.snapshot)
                        if !harness.lastRunSummary.isEmpty {
                            GroupBox {
                                Text(LocalizedStringKey(harness.lastRunSummary))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentTransition(.numericText(countsDown: false))
                                    .animation(.spring, value: harness.snapshot)
                            } label: {
                                HStack {
                                    Text("Last Run")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(harness.timestamp?.formatted(
                                        date: .abbreviated,
                                        time: .standard
                                    ) ?? "nil")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                        GraphCanvasView(
                            snapshot: harness.snapshot,
                            selection: harness.selection,
                            shouldHighlight: harness.shouldHighlight,
                            showLabels: harness.showLabels,
                            filterText: harness.filterText
                        ) {
                            self.harness.selection = $0
                        }
                        .frame(minHeight: 320)
                        HStack(alignment: .top, spacing: 12) {
                            GroupBox("Checks") {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(harness.checks) { check in
                                        HStack {
                                            Image(systemName: check.passed
                                                  ? "checkmark.circle.fill"
                                                  : "xmark.circle.fill"
                                            )
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(LocalizedStringKey(check.name))
                                                    .font(.footnote)
                                                Text(LocalizedStringKey(check.detail.joined(separator: ", ")))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                                .padding(.top, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            GroupBox("Inspector") {
                                InspectorView()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .animation(.spring, value: showSlider)
                    .scrollClipDisabled()
                    .padding()
                }
                .toolbar {
                    if harness.isLoading {
                        ProgressView()
                    }
                    Toggle(
                        "Show Slider",
                        systemImage: "slider.horizontal.below.rectangle",
                        isOn: $showSlider
                    )
                    .toggleStyle(.button)
                    Button("Trim") {
                        harness.trim()
                    }
                    .disabled(
                        harness.snapshot.totalOwners +
                        harness.snapshot.totalTargets <=
                        harness.trimNodeLimit
                    )
                    Button("Reload") {
                        harness.reload(modelContext: modelContext, schema: schema)
                        if autoRun { self.isPresented = true }
                    }
                    .disabled(!harness.isLoading)
                    Button("Close", systemImage: "xmark", role: .cancel) {
                        self.isPresented = false
                    }
                }
            }
            .presentationDetents([.medium, .large], selection: $detent)
            .previewSnapshot(for: $harness.previewIdentifier) { selection in
                if let selection {
                    return (selection.entityName, selection.primaryKey())
                } else {
                    return nil
                }
            }
        }
    }
    
    struct StatChip: View {
        var title: String
        var value: String
        
        var body: some View {
            GroupBox {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.caption).foregroundStyle(.secondary)
                    Text(value).font(.headline)
                }.frame(minWidth: 80, alignment: .leading)
            }
        }
    }
    
    struct Edge: Hashable, Sendable {
        let owner: PersistentIdentifier
        let property: String
        let target: PersistentIdentifier
    }
    
    struct CheckResult: Identifiable {
        var id: String { name }
        let name: String
        let passed: Bool
        let detail: [String]
    }
    
    struct InspectorView: View {
        @Environment(Harness.self) private var harness
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                if let selection = self.harness.selection {
                    Text("\(selection.entityName) Selected")
                        .font(.subheadline)
                    Text(selection.primaryKey())
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Divider()
                    Text("Incoming")
                        .font(.subheadline.weight(.semibold))
                    let incoming = self.harness.graph.incoming(to: selection)
                    IncomingList(edges: incoming)
                    Divider()
                    HStack(spacing: 4) {
                        Text("Outgoing")
                            .fontWeight(.semibold)
                        Text(harness.property.isEmpty ? "(All)" : "(Property: \(harness.property))")
                            .fontWeight(.regular)
                    }
                    .font(.subheadline)
                    let outgoing = self.harness.graph.outgoing(
                        from: selection,
                        property: harness.property.isEmpty ? nil : harness.property
                    )
                    EdgeList(identifiers: outgoing)
                } else {
                    Text("Select a node to inspect.").foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    struct IncomingList: View {
        var edges: [ReferenceGraph.IncomingEdge]
        
        var body: some View {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(edges.enumerated()), id: \.offset) { _, edge in
                        Text("`\(edge.owner.entityName).\(edge.property)` is selected.")
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if edges.isEmpty {
                        Text("None")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 110)
        }
    }
    
    struct EdgeList: View {
        var identifiers: [PersistentIdentifier]
        
        var body: some View {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(identifiers.enumerated()), id: \.offset) { _, identifier in
                        VStack(alignment: .leading, spacing: 4) {
                           EdgeButton(identifier: identifier)
                        }
                        .padding(8)
                        .background(.background.secondary, in: .rect(cornerRadius: 8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if identifiers.isEmpty {
                        Text("None")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 110)
        }
        
        struct EdgeButton: View {
            @Environment(Harness.self) private var harness
            var identifier: PersistentIdentifier
            
            var body: some View {
                let isSelected = harness.previewIdentifier == identifier
                Button {
                    switch isSelected {
                    case true: self.harness.previewIdentifier = nil
                    case false: self.harness.previewIdentifier = identifier
                    }
                } label: {
                    ScrollView(.horizontal) {
                        HStack {
                            Text(identifier.entityName)
                                .font(.caption.weight(.bold))
                            Text("`\(String(describing: identifier.primaryKey()))`")
                                .font(.caption2)
                        }
                        .opacity(isSelected ? 0.5 : 1.0)
                    }
                    .scrollIndicators(.hidden)
                    .scrollClipDisabled()
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    struct GraphCanvasView: View {
        let snapshot: ReferenceGraph.Snapshot
        let selection: PersistentIdentifier?
        let shouldHighlight: Bool
        let showLabels: Bool
        let filterText: String
        let onTap: (PersistentIdentifier) -> Void
        
        var body: some View {
            GeometryReader { proxy in
                let layout = GraphLayout(snapshot, filterText: filterText, size: proxy.size)
                ZStack {
                    Canvas { context, _ in
                        for edge in layout.edges {
                            guard let from = layout.positions[edge.owner],
                                  let to = layout.positions[edge.target] else {
                                continue
                            }
                            var path = Path()
                            path.move(to: from)
                            path.addLine(to: to)
                            let isHot = shouldHighlight &&
                            (selection == edge.owner || selection == edge.target)
                            context.stroke(
                                path,
                                with: .color(isHot ? .accentColor : .secondary.opacity(0.5)),
                                lineWidth: isHot ? 2 : 1
                            )
                        }
                    }
                    ForEach(layout.nodes, id: \.self) { node in
                        let isSelected = node == self.selection
                        Button {
                            onTap(node)
                        } label: {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(
                                        isSelected
                                        ? Color.accentColor
                                        : Color.secondary.opacity(0.25)
                                    )
                                    .frame(
                                        width: isSelected ? 18 : 14,
                                        height: isSelected ? 18 : 14
                                    )
                                if showLabels {
                                    Text(node.entityName)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .frame(maxWidth: 140)
                                }
                            }
                        }
                        .animation(.bouncy, value: layout)
                        .animation(.bouncy, value: snapshot)
                        .animation(.bouncy, value: selection)
                        .buttonStyle(.plain)
                        .position(layout.positions[node] ?? .zero)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.quaternary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Nodes: \(layout.nodes.count)")
                                .animation(.spring, value: layout.nodes.count)
                            Text("Edges: \(layout.edges.count)")
                                .animation(.spring, value: layout.edges.count)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .contentTransition(.numericText(countsDown: false))
                    
                    
                    .padding(10)
                }
            }
        }
    }
    
    struct GraphLayout: Equatable {
        let edges: [Edge]
        let nodes: [PersistentIdentifier]
        let positions: [PersistentIdentifier: CGPoint]
        
        init(_ snapshot: ReferenceGraph.Snapshot, filterText: String, size: CGSize) {
            var edges = [Edge]()
            edges.reserveCapacity(snapshot.totalEdges)
            var nodeSet = Set<PersistentIdentifier>()
            nodeSet.reserveCapacity(snapshot.totalOwners + snapshot.totalTargets)
            for (owner, byProperty) in snapshot.forward {
                nodeSet.insert(owner)
                for (property, targets) in byProperty {
                    for target in targets {
                        nodeSet.insert(target)
                        edges.append(.init(owner: owner, property: property, target: target))
                    }
                }
            }
            var nodes = Array(nodeSet)
            nodes.sort { "\(String(describing: $0))" < "\(String(describing: $1))" }
            if !filterText.isEmpty {
                let needle = filterText.lowercased()
                nodes = nodes.filter {
                    $0.entityName.lowercased().contains(needle) ||
                    String(describing: $0).lowercased().contains(needle)
                }
                let allowed = Set(nodes)
                edges = edges.filter { allowed.contains($0.owner) && allowed.contains($0.target) }
            }
            let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
            let radius = max(40, min(size.width, size.height) * 0.35)
            var positions: [PersistentIdentifier: CGPoint] = [:]
            positions.reserveCapacity(nodes.count)
            for (index, node) in nodes.enumerated() {
                let angle = (Double(index) / Double(max(1, nodes.count))) * (Double.pi * 2.0)
                let x = center.x + CGFloat(cos(angle)) * radius
                let y = center.y + CGFloat(sin(angle)) * radius
                positions[node] = CGPoint(x: x, y: y)
            }
            self.nodes = nodes
            self.edges = edges
            self.positions = positions
        }
    }
    
    @MainActor @Observable final class Harness: Sendable {
        var timestamp: Date?
        var checks: [CheckResult] = []
        var previewIdentifier: PersistentIdentifier?
        var selection: PersistentIdentifier?
        var property: String = ""
        var trimNodeLimit: Int = 40
        var fetchLimit: Int?
        var filterText: String = ""
        var lastRunSummary: String = ""
        var showLabels: Bool = true
        var shouldHighlight: Bool = true
        var relationshipNames: [String] = []
        var isLoading: Bool = false
        var task: Task<Void, Never>?
        var sourceGraph: ReferenceGraph = .init()
        var graph: ReferenceGraph = .init()
        var snapshot: ReferenceGraph.Snapshot = .init(
            forward: [:],
            reverse: [:],
            totalOwners: 0,
            totalTargets: 0,
            totalEdges: 0,
            totalProperties: 0
        )
        
        func refresh() {
            self.snapshot = graph.snapshot()
            self.checks = evaluateChecks()
            self.timestamp = Date()
            if task == nil || task?.isCancelled == false {
                self.isLoading = false
            }
        }
        
        func reload(modelContext: ModelContext, schema: Schema) {
            task?.cancel()
            self.isLoading = true
            self.task = Task {
                
                
                defer {
                    if Task.isCancelled { task = nil }
                }
                var graph = ReferenceGraph()
                var relationshipNames = Set<String>()
                var discoveredNodes = Set<PersistentIdentifier>()
                var loadedModelCount: Int = 0
                for entity in schema.entities {
                    guard let type = entity.type else {
                        continue
                    }
                    do {
                        loadedModelCount += try Self.append(
                            type: type,
                            fetchLimit: fetchLimit,
                            modelContext: modelContext,
                            schema: schema,
                            relationshipNames: &relationshipNames,
                            discoveredNodes: &discoveredNodes,
                            graph: &graph
                        )
                    } catch {
                        Banner(.error, "Fetch Error") {
                            "Unable to collect models: \(error)"
                        }
                    }
                }
                self.sourceGraph = graph
                self.graph = graph
                self.relationshipNames = relationshipNames.sorted()
                if let selection = self.selection, !discoveredNodes.contains(selection) {
                    self.selection = discoveredNodes.first
                } else if self.selection == nil {
                    self.selection = discoveredNodes.first
                }
                if !property.isEmpty && !relationshipNames.contains(property) {
                    self.property = ""
                }
                self.lastRunSummary = "Loaded \(loadedModelCount) models and \(self.relationshipNames.count) relationship properties from the live SwiftData schema."
                refresh()
                self.task = nil
            }
        }
        
        func trim() {
            task?.cancel()
            self.isLoading = true
            self.task = Task {
                
                defer {
                    if Task.isCancelled { task = nil }
                }
                let snapshot = self.sourceGraph.snapshot()
                let orderedNodes = self.orderedNodes(from: snapshot)
                let keep = Set(orderedNodes.prefix(self.trimNodeLimit))
                if Task.isCancelled { return }
                guard !keep.isEmpty else {
                    return
                }
                let trimmedGraph = ReferenceGraph()
                for (owner, byProperty) in snapshot.forward {
                    if Task.isCancelled { return }
                    guard keep.contains(owner) else {
                        continue
                    }
                    for (property, targets) in byProperty {
                        if Task.isCancelled { return }
                        let keptTargets = targets.filter { keep.contains($0) }
                        if !keptTargets.isEmpty {
                            trimmedGraph.set(owner: owner, property: property, targets: keptTargets)
                        }
                    }
                }
                if Task.isCancelled { return }
                self.graph = trimmedGraph
                if let selection = self.selection, !keep.contains(selection) {
                    self.selection = orderedNodes.first(where: keep.contains)
                } else if self.selection == nil {
                    self.selection = orderedNodes.first(where: keep.contains)
                }
                self.lastRunSummary = "Trimmed graph to \(keep.count) prioritized nodes."
                refresh()
                self.task = nil
            }
        }
        
        func untrim() {
            task?.cancel()
            self.isLoading = true
            self.task = Task {
                
                defer {
                    if Task.isCancelled { task = nil }
                }
                self.graph = self.sourceGraph
                self.lastRunSummary = "Restored full graph."
                if Task.isCancelled { return }
                refresh()
            }
        }
        
        private func orderedNodes(from snapshot: ReferenceGraph.Snapshot) -> [PersistentIdentifier] {
            var ordered = [PersistentIdentifier]()
            var seen = Set<PersistentIdentifier>()
            
            func append(_ identifier: PersistentIdentifier) {
                guard seen.insert(identifier).inserted else {
                    return
                }
                ordered.append(identifier)
            }
            
            if let selection = self.selection {
                append(selection)
                
                for edge in self.sourceGraph.incoming(to: selection) {
                    append(edge.owner)
                }
                
                for identifier in self.sourceGraph.outgoing(from: selection, property: nil) {
                    append(identifier)
                }
            }
            
            var degreeByNode = [PersistentIdentifier: Int]()
            
            for (owner, byProperty) in snapshot.forward {
                degreeByNode[owner, default: 0] += byProperty.count
                
                for targets in byProperty.values {
                    degreeByNode[owner, default: 0] += targets.count
                    
                    for target in targets {
                        degreeByNode[target, default: 0] += 1
                    }
                }
            }
            
            let remaining = degreeByNode.keys.sorted { left, right in
                let leftDegree = degreeByNode[left, default: 0]
                let rightDegree = degreeByNode[right, default: 0]
                
                if leftDegree != rightDegree {
                    return leftDegree > rightDegree
                }
                
                return String(describing: left) < String(describing: right)
            }
            
            for identifier in remaining {
                append(identifier)
            }
            
            return ordered
        }
        
        private static func append<Model: PersistentModel>(
            type modelType: Model.Type,
            fetchLimit: Int? = nil,
            modelContext: ModelContext,
            schema: Schema,
            
            relationshipNames: inout Set<String>,
            discoveredNodes: inout Set<PersistentIdentifier>,
            graph: inout ReferenceGraph,
        ) throws -> Int {
            guard let entity = schema.entity(for: modelType) else { return 0 }
            
            let relationships = entity.relationships.sorted { $0.name < $1.name }
            var descriptor = FetchDescriptor<Model>()
            descriptor.fetchLimit = fetchLimit
            let models = try modelContext.fetch(descriptor)
            for relationship in relationships {
                relationshipNames.insert(relationship.name)
            }
            for model in models {
                let owner = model.persistentModelID
                discoveredNodes.insert(owner)
                for relationship in relationships {
                    let targets = identifiers(for: model, relationship: relationship)
                    discoveredNodes.formUnion(targets)
                    graph.set(owner: owner, property: relationship.name, targets: targets)
                }
            }
            
            return models.count
        }
        
        private static func identifiers<Model: PersistentModel>(
            for model: Model,
            relationship: Schema.Relationship
        ) -> [PersistentIdentifier] {
            func cast<T>(_ keyPath: AnyKeyPath, as type: T.Type) -> [PersistentIdentifier]
            where T: PersistentModel {
                switch keyPath {
                case let keyPath as KeyPath<Model, T>:
                    let relatedModel = model.getValue(forKey: keyPath)
                    return [relatedModel.persistentModelID]
                case let keyPath as KeyPath<Model, T?>:
                    if let relatedModel = model.getValue(forKey: keyPath) {
                        return [relatedModel.persistentModelID]
                    }
                default:
                    break
                }
                return []
            }
            func cast<T>(_ keyPath: AnyKeyPath, as type: T.Type) -> [PersistentIdentifier]
            where T: RelationshipCollection & Sequence, T.PersistentElement: PersistentModel {
                switch keyPath {
                case let keyPath as KeyPath<Model, T>:
                    let models = model.getValue(forKey: keyPath)
                    if let relatedModels = models as? [any PersistentModel] {
                        return relatedModels.map { $0.persistentModelID }
                    }
                    var identifiers = [PersistentIdentifier]()
                    for model in models {
                        if let relatedModel = model as? T.PersistentElement {
                            identifiers.append(relatedModel.persistentModelID)
                        }
                    }
                    return identifiers
                case _ as KeyPath<Model, T?>:
                    Banner(.warning, "Incomplete") {
                        "Optional to-many relationships is not implemented."
                    }
                default:
                    break
                }
                return []
            }
            guard let property = Model.schemaMetadata(for: relationship.name) else {
                return []
            }
            switch property.valueType {
            case let type as any PersistentModel.Type:
                return cast(property.keyPath, as: type)
            case let type as any (RelationshipCollection & Sequence).Type:
                return cast(property.keyPath, as: type)
            default:
                return []
            }
        }
        
        private func evaluateChecks() -> [CheckResult] {
            let integrity = self.graph.verifyIntegrity(logLevel: .info)
            return [
                .init(
                    name: "Forward/Reverse Symmetry",
                    passed: integrity,
                    detail: [integrity ? "`OK`" : "`FAILED`"]
                ),
                .init(
                    name: "Relationship Properties Discovered",
                    passed: !relationshipNames.isEmpty,
                    detail: ["`count = \(relationshipNames.count)`"]
                ),
                .init(
                    name: "Live Graph Loaded",
                    passed: snapshot.totalOwners > 0 || snapshot.totalTargets > 0,
                    detail: [
                        "`owners = \(snapshot.totalOwners)`",
                        "`targets = \(snapshot.totalTargets)`"
                    ]
                )
            ]
        }
    }
}
