//
//  ReferenceGraphView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import DataStoreRuntime
import DataStoreSupport
import SwiftData
import SwiftUI
import Synchronization

extension String {
    static var isCollapsed: Self {
        "controls-visibility"
    }
    
    nonisolated static var nodeLabelPlacement: Self {
        "node-label-placement"
    }
}

extension EnvironmentValues {
    @Entry fileprivate var identifiers: [PersistentIdentifier] = []
    @Entry fileprivate var selectedEntityName: Binding<String?> = .constant(nil)
}

struct ReferenceGraphView: View {
    @DatabaseActor @Environment(Database.self) private var database
    @Environment(\.schema) private var schema
    @State private var view: Graph?
    @State private var identifiers: [PersistentIdentifier] = []
    
    var body: some View {
        VStack {
            if let view = self.view {
                GraphCanvas()
                    .filteredGraphCanvas()
                    .overlay(alignment: .topLeading) {
                        ControlBox()
                            .environment(\.identifiers, identifiers)
                            .padding(8)
                    }
                    .overlay(alignment: .bottom) {
                        if !view.selection.isEmpty {
                            let selectionCount = view.selection.count
                            let clearTitle =
                            selectionCount == view.nodes.count ? "Clear All \(selectionCount)" :
                            selectionCount == 1 ? "Clear" : "Clear \(selectionCount)"
                            Button(clearTitle, role: .cancel) {
                                withAnimation(.smooth.speed(0.15)) {
                                    view.selection.removeAll()
                                }
                            }
                            .contentTransition(.numericText(countsDown: true))
                            .buttonStyle(.borderedProminent)
                            .transition(.scale)
                        }
                    }
                    .animation(.spring, value: view.selection.isEmpty)
                    .animation(.spring, value: view.selection.count)
                    .environment(view)
            } else {
                ProgressView()
                    .task(priority: .high) { @DatabaseActor in
                        if let manager = self.database.stores.first?.value.manager {
                            let identifiers = Array(manager.editingStates.withLock { $0.keys })
                            let roots = identifiers.prefix(1)
                            await MainActor.run {
                                self.identifiers = identifiers
                                self.view = Graph(
                                    graph: manager.graph,
                                    roots: Array(roots),
                                    configurations: .init(
                                        depthOutgoing: 1,
                                        depthIncoming: 0,
                                        direction: .both
                                    ),
                                    plugins: .init(
                                        label: CustomGraphLabel(schema: schema),
                                        style: CustomGraphStyle(schema: schema),
                                        interaction: CustomGraphInteraction(schema: schema)
                                    )
                                )
                            }
                        }
                    }
            }
        }
        .safeAreaPadding()
    }
    
    struct ControlBox: View {
        @Environment(Graph.self) private var view
        @Environment(\.identifiers) private var identifiers: [PersistentIdentifier]
        @State private var selectedEntityName: String? = nil
        @AppStorage(.isCollapsed) private var controlsCollapsed: Bool = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    AsyncButton("Focus") {
                        let roots = Array(view.selection)
                        if !roots.isEmpty { view.setRoots(roots) }
                    }
                    .buttonStyle(.borderedProminent)
                    AsyncButton("Reset") {
                        if !identifiers.isEmpty {
                            withAnimation(.spring()) { view.setRoots(identifiers) }
                        }
                    }
                    .buttonStyle(.bordered)
                    NodeLabelPicker()
                    ResizeToggle().buttonStyle(.bordered)
                }
                DetailView()
                    .environment(\.selectedEntityName, $selectedEntityName)
            }
            .padding(10)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .animation(.spring, value: controlsCollapsed)
        }
        
        struct NodeLabelPicker: View {
            @AppStorage(.nodeLabelPlacement)
            private var nodeLabelPlacement: NodeLabelPlacement = .outerEdge
            
            var body: some View {
                Menu {
                    ForEach(NodeLabelPlacement.allCases) { placement in
                        Button(placement.title) { self.nodeLabelPlacement = placement }
                    }
                } label: {
                    Image(systemName: "textformat")
                }
                .buttonStyle(.bordered)
            }
        }
        
        struct ResizeToggle: View {
            @AppStorage(.isCollapsed) private var controlsCollapsed: Bool = false
            
            var body: some View {
                Button {
                    withAnimation(.snappy) { controlsCollapsed.toggle() }
                } label: {
                    Image(systemName: controlsCollapsed ? "chevron.down" : "chevron.up")
                }
            }
        }
        
        struct DetailView: View {
            @Environment(Graph.self) private var view
            @Environment(\.identifiers) private var identifiers: [PersistentIdentifier]
            @Environment(\.selectedEntityName) private var selectedEntityName
            @AppStorage(.isCollapsed) private var controlsCollapsed: Bool = false
            
            var body: some View {
                let entityNames = Array(Set(identifiers.map(\.entityName))).sorted()
                if !controlsCollapsed {
                    Text("\(view.nodes.count) nodes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        Stepper("Out \(view.configurations.depthOutgoing)", value: Binding(
                            get: { view.configurations.depthOutgoing },
                            set: { view.configurations.depthOutgoing = $0; view.rebuild() }
                        ), in: 0...6)
                        Stepper("In \(view.configurations.depthIncoming)", value: Binding(
                            get: { view.configurations.depthIncoming },
                            set: { view.configurations.depthIncoming = $0; view.rebuild() }
                        ), in: 0...6)
                    }
                    HStack(spacing: 12) {
                        Picker("Direction", selection: Binding(
                            get: { view.configurations.direction },
                            set: { view.configurations.direction = $0; view.rebuild() }
                        )) {
                            Text("Out").tag(GraphExploreDirection.outgoing)
                            Text("In").tag(GraphExploreDirection.incoming)
                            Text("Both").tag(GraphExploreDirection.both)
                        }
                        .pickerStyle(.segmented)
                        Stepper("Max \(view.configurations.maxNodes)", value: Binding(
                            get: { view.configurations.maxNodes },
                            set: { view.configurations.maxNodes = $0; view.rebuild() }
                        ), in: 50...2000, step: 50)
                    }
                    HStack(spacing: 8) {
                        FilterTextField(text: Binding(
                            get: { view.searchText },
                            set: { view.searchText = $0 }
                        ))
                        Menu {
                            Button("All Types") {
                                selectedEntityName.wrappedValue = nil
                            }
                            let types = entityNames
                            if !types.isEmpty {
                                Divider()
                                ForEach(types, id: \.self) { name in
                                    Button(name) { selectedEntityName.wrappedValue = name }
                                }
                            }
                        } label: {
                            Label(selectedEntityName.wrappedValue ?? "All", systemImage: "tag")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.bordered)
                    }
                    SearchResult(entityNames: entityNames)
                }
            }
        }
        
        struct FilterTextField: View {
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
        
        struct SearchResult: View {
            @Environment(Graph.self) private var view
            @Environment(\.selectedEntityName) private var selectedEntityName
            var entityNames: [String]
            
            var body: some View {
                let query = self.view.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !query.isEmpty || selectedEntityName.wrappedValue != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        MatchedTypes(query: query, entityNames: entityNames)
                    }
                }
            }
            
            struct MatchedTypes: View {
                var query: String
                var entityNames: [String]
                
                var body: some View {
                    let matchedTypes = self.matchingEntityNames
                    if !query.isEmpty && !matchedTypes.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(matchedTypes, id: \.self) { name in
                                    TypeButton(name: name).buttonStyle(.bordered)
                                }
                            }
                        }
                        MatchedResult(query: query)
                            .animation(.snappy, value: query)
                            .frame(maxHeight: 200)
                    } else {
                        ContentUnavailableView(
                            "No Matches",
                            systemImage: "magnifyingglass"
                        )
                        .frame(maxHeight: 200)
                    }
                }
                
                private var matchingEntityNames: [String] {
                    let normalizedQuery = self.query.lowercased()
                    guard !normalizedQuery.isEmpty else { return [] }
                    return entityNames
                        .filter { $0.lowercased().contains(normalizedQuery) }
                        .prefix(12)
                        .map { $0 }
                }
            }
            
            struct TypeButton: View {
                @Environment(\.selectedEntityName) private var selectedEntityName
                var name: String
                
                var body: some View {
                    Button {
                        self.selectedEntityName.wrappedValue = name
                    } label: {
                        Text(name)
                    }
                }
            }
            
            struct MatchedResult: View {
                @Environment(Graph.self) private var view
                @Environment(\.selectedEntityName) private var selectedEntityName
                @Environment(\.identifiers) private var identifiers: [PersistentIdentifier]
                var query: String
                
                var body: some View {
                    let matches = self.matchingIdentifiers
                    if !matches.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Matches (\(min(matches.count, 30)))")
                                .font(.caption)
                                .foregroundStyle(.secondary.blendMode(.plusDarker))
                            ScrollView {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(Array(matches.prefix(30)), id: \.self) { id in
                                        ResultItem(identifier: id).buttonStyle(.bordered)
                                    }
                                }
                            }
                            .clipShape(.rect(cornerRadius: 8))
                        }
                    }
                }
                
                private var matchingIdentifiers: [PersistentIdentifier] {
                    let entityName = self.selectedEntityName.wrappedValue
                    let normalizedQuery = self.query.lowercased()
                    return identifiers.filter { identifier in
                        if let entityName, identifier.entityName != entityName {
                            return false
                        }
                        if normalizedQuery.isEmpty {
                            return true
                        }
                        if identifier.entityName.lowercased().contains(normalizedQuery) {
                            return true
                        }
                        return String(describing: identifier)
                            .lowercased()
                            .contains(normalizedQuery)
                    }
                }
                
                struct ResultItem: View {
                    @Environment(Graph.self) private var view
                    var identifier: PersistentIdentifier
                    
                    var body: some View {
                        Button {
                            view.setRoots([identifier])
                            withAnimation(.snappy) {
                                view.selection = [identifier]
                            }
                        } label: {
                            EntityRow(identifier: identifier)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                
                struct EntityRow: View {
                    @Environment(Graph.self) private var view
                    var identifier: PersistentIdentifier
                    
                    var body: some View {
                        VStack(alignment: .leading, spacing: 2) {
                            let incoming = self.view.graph.incoming(to: identifier)
                            HStack {
                                if let edge = incoming.sorted(by: { $0.property < $1.property }).first {
                                    Text("\(edge.owner.entityName).\(edge.property)")
                                        .font(.caption.weight(.semibold))
                                } else {
                                    Text(identifier.entityName)
                                        .font(.caption.weight(.semibold))
                                }
                                if let storeIdentifier = self.identifier.storeIdentifier {
                                    Spacer()
                                    Text(storeIdentifier)
                                        .font(.caption.weight(.semibold))
                                        .padding(3)
                                        .background(
                                            Color.accentColor.opacity(0.1),
                                            in: .rect(cornerRadius: 5)
                                        )
                                }
                            }
                            Text(identifier.primaryKey())
                                .font(.caption2.weight(.bold).monospaced())
                                .foregroundStyle(.link.secondary)
                        }
                        .lineLimit(1)
                        .truncationMode(.middle)
                    }
                }
            }
        }
    }
}
