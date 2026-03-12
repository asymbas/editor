//
//  ReferenceGraphListView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Combine
import DataStoreKit
import DataStoreRuntime
import Foundation
import SwiftData
import SwiftUI
import Synchronization

#Preview(traits: .defaultData) {
    NavigationStack {
        ReferenceGraphListView()
    }
}

struct ReferenceGraphListView: View {
    @Environment(Database.self) private var database
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(Array(database.stores.values), id: \.identifier) { store in
                    InspectorView(graph: store.manager.graph)
                        .frame(width: 380)
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: .black.opacity(0.25), radius: 25)
                        .padding()
                        .scrollTargetLayout()
                }
            }
        }
        .scrollTargetBehavior(.paging)
    }
    
    @MainActor @Observable final class Model {
        nonisolated private unowned let graph: ReferenceGraph
        var snapshot: ReferenceGraph.Snapshot
        
        init(graph: ReferenceGraph) {
            self.graph = graph
            self.snapshot = graph.snapshot()
        }
        
        func refresh() {
            self.snapshot = graph.snapshot()
        }
        
        func ownerSortKey(for persistentIdentifier: PersistentIdentifier) -> String {
            "\(persistentIdentifier.entityName)-\(String(describing: persistentIdentifier))"
        }
    }
    
    struct InspectorView: View {
        @State private var view: Model
        @State private var mode: DisplayMode = .forward
        @State private var searchText: String = ""
        
        init(graph: ReferenceGraph) {
            _view = State(initialValue: .init(graph: graph))
        }
        
        enum DisplayMode: String, CaseIterable, Identifiable {
            case forward = "Outgoing"
            case reverse = "Incoming"
            
            var id: Self { self }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                let snapshot = self.view.snapshot
                HStack(spacing: 16) {
                    MetricHeaderView(title: "Owners", value: snapshot.totalOwners)
                    MetricHeaderView(title: "Targets", value: snapshot.totalTargets)
                    MetricHeaderView(title: "Edges", value: snapshot.totalEdges)
                }
                .font(.subheadline)
                Picker("Mode", selection: $mode) {
                    ForEach(DisplayMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                TextField("Filter by entity or identifier", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                Divider()
                Group {
                    switch mode {
                    case .forward:
                        ForwardList(
                            onOwnerMatches: { ownerMatchesSearch($0, snapshot: $1) },
                            ownerLabel: { ownerLabel($0) },
                            targetLabel: { targetLabel($0) }
                        )
                    case .reverse:
                        ReverseList(
                            onTargetSelected: { targetMatchesSearch($0, snapshot: $1) },
                            onOwnerMatches: { ownerMatchesSearch($0, snapshot: $1) },
                            ownerLabel: { ownerLabel($0) },
                            targetLabel: { targetLabel($0) }
                        )
                    }
                }
            }
            .environment(view)
            .safeAreaPadding()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        view.refresh()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        
        struct MetricHeaderView: View {
            var title: String
            var value: Int
            
            var body: some View {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundStyle(.secondary)
                    Text("\(value)")
                        .font(.headline)
                }
            }
        }
        
        struct ForwardList: View {
            @Environment(Model.self) private var view
            var onOwnerMatches: (PersistentIdentifier, ReferenceGraph.Snapshot) -> Bool
            var ownerLabel: (PersistentIdentifier) -> String
            var targetLabel: (PersistentIdentifier) -> String
            
            var body: some View {
                let snapshot = self.view.snapshot
                let owners = snapshot.forward.keys.sorted { lhs, rhs in
                    view.ownerSortKey(for: lhs) < view.ownerSortKey(for: rhs)
                }
                let filteredOwners = owners.filter { onOwnerMatches($0, snapshot) }
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(filteredOwners, id: \.self) { owner in
                            if let byProperty = snapshot.forward[owner] {
                                Section {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(byProperty.keys.sorted(), id: \.self) { property in
                                            if let targets = byProperty[property] {
                                                PropertyRow(
                                                    property: property,
                                                    targets: targets,
                                                    label: targetLabel
                                                )
                                            }
                                        }
                                    }
                                } header: {
                                    Text(ownerLabel(owner))
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        struct ReverseList: View {
            @Environment(Model.self) private var view
            var onTargetSelected: (PersistentIdentifier, ReferenceGraph.Snapshot) -> Bool
            var onOwnerMatches: (PersistentIdentifier, ReferenceGraph.Snapshot) -> Bool
            var ownerLabel: (PersistentIdentifier) -> String
            var targetLabel: (PersistentIdentifier) -> String
            
            var body: some View {
                let snapshot = self.view.snapshot
                let targets = snapshot.reverse.keys.sorted { lhs, rhs in
                    view.ownerSortKey(for: lhs) < view.ownerSortKey(for: rhs)
                }
                let filteredTargets = targets.filter { onTargetSelected($0, snapshot) }
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(filteredTargets, id: \.self) { target in
                            if let edges = snapshot.reverse[target] {
                                Section {
                                    VStack(alignment: .leading, spacing: 6) {
                                        #if swift(>=6.2)
                                        let keys = edges.sorted(by: edgeSortKey)
                                        #else
                                        let keys = try! edges.sorted(by: edgeSortKey)
                                        #endif
                                        ForEach(keys, id: \.self) { edge in
                                            HStack {
                                                Text(edge.property)
                                                    .font(.caption)
                                                Spacer()
                                                Text(ownerLabel(edge.owner))
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                            .padding(.vertical, 2)
                                        }
                                    }
                                } header: {
                                    Text(targetLabel(target))
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
            
            private func edgeSortKey(
                _ lhs: ReferenceGraph.IncomingEdge,
                _ rhs: ReferenceGraph.IncomingEdge
            ) -> Bool {
                let lhs = "\(lhs.owner.entityName).\(lhs.property)"
                let rhs = "\(rhs.owner.entityName).\(rhs.property)"
                return lhs < rhs
            }
        }
        
        struct PropertyRow: View {
            var property: String
            var targets: [PersistentIdentifier]
            var label: (PersistentIdentifier) -> String
            
            var body: some View {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(property)
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(targets.count) target\(targets.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if !targets.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(targets, id: \.self) { target in
                                    Text(label(target))
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Capsule().strokeBorder(.secondary.opacity(0.4)))
                                }
                            }
                        }
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
            }
        }
        
        private func ownerLabel(_ persistentIdentifier: PersistentIdentifier) -> String {
            displayLabel(persistentIdentifier: persistentIdentifier)
        }
        
        private func targetLabel(_ persistentIdentifier: PersistentIdentifier) -> String {
            displayLabel(persistentIdentifier: persistentIdentifier)
        }
        
        private func displayLabel(persistentIdentifier: PersistentIdentifier) -> String {
            let raw = persistentIdentifier.primaryKey()
            let suffix = raw.suffix(6)
            return "\(persistentIdentifier.entityName)#\(suffix)"
        }
        
        private func ownerMatchesSearch(
            _ owner: PersistentIdentifier,
            snapshot: ReferenceGraph.Snapshot
        ) -> Bool {
            guard !searchText.isEmpty else { return true }
            let term = self.searchText.lowercased()
            if owner.entityName.lowercased().contains(term) ||
                String(describing: owner).lowercased().contains(term) {
                return true
            }
            if let byProperty = snapshot.forward[owner] {
                for (property, targets) in byProperty {
                    if property.lowercased().contains(term) {
                        return true
                    }
                    if targets.contains(where: {
                        $0.entityName.lowercased().contains(term) ||
                        String(describing: $0).lowercased().contains(term)
                    }) {
                        return true
                    }
                }
            }
            return false
        }
        
        private func targetMatchesSearch(
            _ target: PersistentIdentifier,
            snapshot: ReferenceGraph.Snapshot
        ) -> Bool {
            guard !searchText.isEmpty else { return true }
            let term = searchText.lowercased()
            if target.entityName.lowercased().contains(term)
                || String(describing: target).lowercased().contains(term) {
                return true
            }
            if let edges = snapshot.reverse[target] {
                for edge in edges {
                    if edge.property.lowercased().contains(term) {
                        return true
                    }
                    if edge.owner.entityName.lowercased().contains(term) ||
                        String(describing: edge.owner).lowercased().contains(term) {
                        return true
                    }
                }
            }
            return false
        }
    }
}
