//
//  ConstraintTestView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import Logging
import SwiftData
import SwiftUI

#if canImport(Shared)
import Shared
#endif

#Preview(traits: .defaultData) {
    NavigationStack {
        ConstraintTestView()
    }
}

extension String {
    nonisolated static var tabConstraint: Self {
        "tab-constraint"
    }
}

struct ConstraintTestView: View {
    @AppStorage(.tabConstraint) private var tab: TabConstraint = .deleteRule
    
    enum TabConstraint: String, CaseIterable, Identifiable {
        case deleteRule = "delete rule"
        case cardinality
        
        var id: Self { self }
    }
    
    var body: some View {
        VStack {
            switch tab {
            case .deleteRule: DeleteRuleTestView()
            case .cardinality: CardinalityTestView()
            }
        }
        .environment(\.schema, Schema(versionedSchema: ConstraintSchema.self))
        .modifier(TransientModelContainerModifier(types: ConstraintSchema.models))
        .toolbar {
            ToolbarItem {
                Picker("Constraint", selection: $tab) {
                    ForEach(TabConstraint.allCases) { tab in
                        Text(tab.rawValue.capitalized).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
        }
    }
}

struct DeleteRuleTestView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var id: Date = .now
    @State private var scenario: Scenario = .cascade
    @State private var lastError: String?
    @State private var touchRelationshipsBeforeDelete: Bool = true
    
    enum Scenario: String, CaseIterable, Identifiable {
        case cascade
        case nullify
        case deny
        
        var id: Self { self }
    }
    
    var body: some View {
        Form {
            Section("Scenario") {
                Picker("Delete Rule", selection: $scenario) {
                    ForEach(Scenario.allCases) { scenario in
                        Text(scenario.rawValue.capitalized).tag(scenario)
                    }
                }
                Toggle(
                    "Touch Relationships Before Delete",
                    isOn: $touchRelationshipsBeforeDelete
                )
            }
            Section("Actions") {
                Button("Seed") {
                    run { try seed(); try modelContext.save(); lastError = nil }
                }
                Button("Delete Parent") {
                    run { try deleteParentOnly(); lastError = nil }
                }
                Button("Delete Child") {
                    run { try deleteChildOnly(); lastError = nil }
                }
                Button("Save") {
                    run { try modelContext.save(); lastError = nil }
                }
                Button("Reset and Delete All", role: .destructive) {
                    run { resetAll(); try modelContext.save(); lastError = nil }
                }
            }
            Section {
                Group {
                    Text("\(modelContext.editingState.id)")
                    switch scenario {
                    case .cascade:
                        countRow("Cascade Parents", DeleteRuleCascadeParent.self)
                        countRow("Cascade Children", DeleteRuleCascadeChild.self)
                    case .nullify:
                        countRow("Nullify Parents", DeleteRuleNullifyParent.self)
                        countRow("Nullify Children", DeleteRuleNullifyChild.self)
                    case .deny:
                        countRow("Deny Parents", DeleteRuleDenyParent.self)
                        countRow("Deny Children", DeleteRuleDenyChild.self)
                    }
                }
                .id(id)
            } header: {
                HStack {
                    Text("Counts")
                    Button("Refresh") {
                        self.id = Date.now
                    }
                }
            }
            if let lastError = self.lastError {
                Section("Last Error") {
                    Text(lastError)
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Delete Rule Save Requests")
        .onAppear {
            logger.debug("ModelContext ID on appear: \(Unmanaged.passUnretained(modelContext).toOpaque()) id: \(modelContext.editingState.id)")
        }
    }
    
    private func run(_ operation: () throws -> Void) {
        do {
            try operation()
            logger.debug("ModelContext ID after running operation: \(Unmanaged.passUnretained(modelContext).toOpaque()) id: \(modelContext.editingState.id)")
            self.id = .now
        } catch {
            lastError = String(describing: error)
        }
    }
    
    private func countRow<T: PersistentModel>(_ title: String, _ type: T.Type) -> some View {
        let count = (try? modelContext.fetchCount(FetchDescriptor<T>())) ?? 0
        return HStack {
            Text(title)
            Spacer()
            Text("\(count)").foregroundStyle(.secondary)
        }
    }
    
    private func seed() throws {
        switch scenario {
        case .cascade:
            let parent = DeleteRuleCascadeParent(name: "Cascade Parent")
            let a = DeleteRuleCascadeChild(name: "A", parent: parent)
            let b = DeleteRuleCascadeChild(name: "B", parent: parent)
            let c = DeleteRuleCascadeChild(name: "C", parent: parent)
            modelContext.insert(parent)
            modelContext.insert(a)
            modelContext.insert(b)
            modelContext.insert(c)
        case .nullify:
            let parent = DeleteRuleNullifyParent(name: "Nullify Parent")
            let a = DeleteRuleNullifyChild(name: "A", parent: parent)
            let b = DeleteRuleNullifyChild(name: "B", parent: parent)
            let c = DeleteRuleNullifyChild(name: "C", parent: parent)
            modelContext.insert(parent)
            modelContext.insert(a)
            modelContext.insert(b)
            modelContext.insert(c)
        case .deny:
            let parent = DeleteRuleDenyParent(name: "Deny Parent")
            let a = DeleteRuleDenyChild(name: "A", parent: parent)
            let b = DeleteRuleDenyChild(name: "B", parent: parent)
            let c = DeleteRuleDenyChild(name: "C", parent: parent)
            modelContext.insert(parent)
            modelContext.insert(a)
            modelContext.insert(b)
            modelContext.insert(c)
        }
        self.id = .now
    }
    
    private func deleteParentOnly() throws {
        defer {
            do {
                try modelContext.save()
            } catch {
                logger.error("\(error)")
            }
        }
        switch scenario {
        case .cascade:
            let parents = try modelContext.fetch(FetchDescriptor<DeleteRuleCascadeParent>())
            guard let parent = parents.randomElement() else { return }
            if touchRelationshipsBeforeDelete { _ = parent.children.map(\.id) }
            modelContext.delete(parent)
        case .nullify:
            let parents = try modelContext.fetch(FetchDescriptor<DeleteRuleNullifyParent>())
            guard let parent = parents.randomElement() else { return }
            if touchRelationshipsBeforeDelete { _ = parent.children.map(\.id) }
            modelContext.delete(parent)
        case .deny:
            let parents = try modelContext.fetch(FetchDescriptor<DeleteRuleDenyParent>())
            guard let parent = parents.randomElement() else { return }
            if touchRelationshipsBeforeDelete { _ = parent.children.map(\.id) }
            modelContext.delete(parent)
        }
    }
    
    private func deleteChildOnly() throws {
        switch scenario {
        case .cascade:
            let children = try modelContext.fetch(FetchDescriptor<DeleteRuleCascadeChild>())
            guard let child = children.randomElement() else { return }
            modelContext.delete(child)
        case .nullify:
            let children = try modelContext.fetch(FetchDescriptor<DeleteRuleNullifyChild>())
            guard let child = children.randomElement() else { return }
            modelContext.delete(child)
        case .deny:
            let children = try modelContext.fetch(FetchDescriptor<DeleteRuleDenyChild>())
            guard let child = children.randomElement() else { return }
            modelContext.delete(child)
        }
    }
    
    private func resetAll() {
        deleteAll(DeleteRuleCascadeChild.self)
        deleteAll(DeleteRuleCascadeParent.self)
        deleteAll(DeleteRuleNullifyChild.self)
        deleteAll(DeleteRuleNullifyParent.self)
        deleteAll(DeleteRuleDenyChild.self)
        deleteAll(DeleteRuleDenyParent.self)
    }
    
    private func deleteAll<T: PersistentModel>(_ type: T.Type) {
        if let models = try? modelContext.fetch(FetchDescriptor<T>()) {
            for model in models { modelContext.delete(model) }
        }
    }
}

struct CardinalityTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.schema) private var schema
    @State private var count: Int = 10
    
    var body: some View {
        List {
            Section("Cardinality Violation") {
                if let child = self.schema.entity(for: CardinalityChild.self),
                   let parent = self.schema.entity(for: CardinalityParent.self),
                   let relationship = child.relationshipsByName["parent"],
                   let inverseName = relationship.inverseName,
                   let inverseRelationship = parent.relationshipsByName[inverseName] {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Inserting a parent entity `\(parent.name)` with \(count) `\(child.name)` children into the `ModelContext`.")
                            .font(.caption)
                        Stepper("Amount (\(count))", value: $count)
                            .fontWeight(.medium)
                        Divider()
                        RelationshipCardinalityView(
                            entity: parent,
                            relationship: inverseRelationship
                        )
                        Divider()
                        RelationshipCardinalityView(
                            entity: child,
                            relationship: relationship
                        )
                    }
                    .contentTransition(.numericText(countsDown: false))
                    .animation(.spring, value: count)
                    Button("Insert") {
                        let child = CardinalityChild(name: "test")
                        let parent = CardinalityParent(name: "test", children: [child])
                        modelContext.insert(parent)
                        for _ in 0..<count {
                            let child = CardinalityChild(name: UUID().uuidString)
                            parent.children.append(child)
                        }
                        do {
                            try modelContext.save()
                            Banner.ok("Inserted")
                        } catch {
                            modelContext.rollback()
                            Banner.error("Insert Error") {
                                "Insert failed: \(error)"
                            }
                        }
                    }
                }
            }
        }
    }
    
    struct RelationshipCardinalityView: View {
        var entity: Schema.Entity
        var relationship: Schema.Relationship
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("`\(entity.name).\(relationship.name)`")
                    .font(.headline.bold())
                LabeledContent("Maximum Relationships") {
                    Text("\(relationship.maximumModelCount, default: "nil")")
                }
                LabeledContent("Minimum Relationships") {
                    Text("\(relationship.minimumModelCount, default: "nil")")
                }
            }
            .fontWeight(.medium)
        }
    }
}
