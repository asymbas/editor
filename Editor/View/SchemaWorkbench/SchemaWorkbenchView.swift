//
//  SchemaWorkbenchView.swift
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

#Preview(traits: .defaultData) {
    NavigationStack {
        SchemaWorkbenchView()
    }
}

extension String {
    nonisolated static var tabSchemaWorkbench: Self {
        "tab-schema-workbench"
    }
}

extension UserDefaults {
    @MainActor fileprivate static let schemaWorkbench: UserDefaults? = .init(suiteName: "SchemaWorkbench")
}

struct SchemaWorkbenchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.schema) private var schema
    private var scenarios: [Any]
    
    @AppStorage(.tabSchemaWorkbench, store: .schemaWorkbench)
    private var tab: TabSchemaWorkbench = .overview
    
    init(scenarios: [SchemaWorkbench.Scenario] = []) {
        self.scenarios = scenarios
    }
    
    var body: some View {
        TabView(selection: $tab) {
            ForEach(TabSchemaWorkbench.allCases) { container in
                VStack {
                    switch container {
                    case .overview: OverviewTabView()
                    case .entities: EntitiesTabView()
                    case .relationships: RelationshipsTabView()
                    case .migration: MigrationTabView()
                    case .runtime: RuntimeTabView()
                    case .scenarios: ScenariosTabView(scenarios: scenarios)
                    }
                }
                .tag(container.id)
                .tabItem {
                    Label(container.title, systemImage: container.systemImage)
                }
            }
        }
        .navigationTitle("Schema Workbench")
        .defaultAppStorage(.schemaWorkbench ?? .standard)
    }
    
    enum TabSchemaWorkbench: String, CaseIterable, Equatable, Hashable, Identifiable {
        case overview
        case entities
        case relationships
        case migration
        case runtime
        case scenarios
        
        var id: Self { self }
        
        var title: String {
            rawValue.capitalized
        }
        
        var systemImage: String {
            switch self {
            case .overview: "rectangle.3.group"
            case .entities: "list.bullet.rectangle"
            case .relationships: "arrow.triangle.branch"
            case .migration: "arrow.triangle.2.circlepath"
            case .runtime: "waveform.path.ecg"
            case .scenarios: "play.circle"
            }
        }
    }
    
    struct OverviewTabView: View {
        var body: some View {
            List {
                Section("Summary", content: SummaryView.init)
                Section("Diagnostics", content: DiagnosticsView.init)
            }
        }
        
        struct SummaryView: View {
            @Environment(\.schema) private var schema
            @State private var summary: SchemaWorkbench.Summary?
            
            var body: some View {
                Group {
                    LabeledContent(
                        "Entities",
                        value: "\(summary?.entities ?? 0)"
                    )
                    LabeledContent(
                        "Attributes",
                        value: "\(summary?.attributes ?? 0)"
                    )
                    LabeledContent(
                        "Relationships",
                        value: "\(summary?.relationships ?? 0)"
                    )
                    LabeledContent(
                        "Indices",
                        value: "\(summary?.indices ?? 0)"
                    )
                    LabeledContent(
                        "Uniqueness Constraints",
                        value: "\(summary?.uniquenessConstraints ?? 0)"
                    )
                }
                .task(id: schema) {
                    var attributeCount = 0
                    var relationshipCount = 0
                    var indicesCount = 0
                    var uniquenessConstraintsCount = 0
                    for entity in schema.entities {
                        indicesCount += entity.indices.count
                        uniquenessConstraintsCount += entity.uniquenessConstraints.count
                        attributeCount += entity.attributes.count
                        relationshipCount += entity.relationships.count
                    }
                    self.summary = .init(
                        entities: schema.entities.count,
                        attributes: attributeCount,
                        relationships: relationshipCount,
                        indices: indicesCount,
                        uniquenessConstraints: uniquenessConstraintsCount
                    )
                }
            }
        }
        
        struct DiagnosticsView: View {
            @Environment(\.schema) private var schema
            @State private var issues: [SchemaWorkbench.Issue] = []
            
            var body: some View {
                Group {
                    if !issues.isEmpty {
                        ForEach(issues) { issue in
                            HStack(alignment: .top) {
                                Image(systemName: issue.severity.systemImage)
                                    .foregroundStyle(issue.severity.color)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(issue.code.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(LocalizedStringKey(issue.description))
                                        .font(.footnote)
                                        .textSelection(.enabled)
                                    if let entity = issue.entityName {
                                        Text(
                                            [entity, issue.relationshipName]
                                                .compactMap { $0 }
                                                .joined(separator: ".")
                                        )
                                        .font(.caption2.weight(.medium).monospaced())
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } else {
                        Text("No Issues Found")
                            .foregroundStyle(.placeholder)
                    }
                }
                .task(id: schema) {
                    self.issues = SchemaWorkbench.Issue.run(schema: schema)
                }
            }
        }
    }
    
    struct EntitiesTabView: View {
        @Environment(\.schema) private var schema
        @State private var searchText: String = ""
        
        var body: some View {
            List {
                ForEach(entities, id: \.name) { entity in
                    NavigationLink(entity.name) {
                        EntityDetailView(entity: entity)
                    }
                }
            }
            .searchable(text: $searchText, placement: .toolbar)
        }
        
        private var entities: [Schema.Entity] {
            let all = self.schema.entities.sorted { $0.name < $1.name }
            guard searchText.isEmpty == false else { return all }
            return all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    struct RelationshipsTabView: View {
        @Environment(\.schema) private var schema
        @State private var selectedEntityName: String?
        
        var body: some View {
            let incoming = SchemaWorkbench.IncomingEdge.run(schema: schema)
            List {
                Section {
                    Picker("Entity", selection: $selectedEntityName) {
                        Text("None").tag(String?.none)
                        Divider()
                        ForEach(
                            schema.entities.sorted(by: { $0.name < $1.name }),
                            id: \.name
                        ) { entity in
                            Text(entity.name).tag(String?.some(entity.name))
                        }
                    }
                }
                if let selectedEntityName = self.selectedEntityName,
                   let entity = self.schema.entitiesByName[selectedEntityName] {
                    Section("Outgoing") {
                        if !entity.relationships.isEmpty {
                            ForEach(Array(entity.relationships), id: \.name) { relationship in
                                EdgeView(
                                    source: entity.name,
                                    property: relationship.name,
                                    destination: relationship.destination,
                                    deleteRule: relationship.deleteRule,
                                    isToOneRelationship: relationship.isToOneRelationship,
                                    isOptional: relationship.isOptional,
                                    isUnique: relationship.isUnique
                                )
                            }
                        } else {
                            Text("No Outgoing Relationships")
                                .foregroundStyle(.placeholder)
                        }
                    }
                    Section("Incoming") {
                        if let edges = incoming[selectedEntityName], !edges.isEmpty {
                            ForEach(edges) { edge in
                                EdgeView(
                                    source: edge.source,
                                    property: edge.property,
                                    destination: edge.destination,
                                    deleteRule: edge.deleteRule,
                                    isToOneRelationship: edge.isToOneRelationship,
                                    isOptional: edge.isOptional,
                                    isUnique: edge.isUnique
                                )
                            }
                        } else {
                            Text("No Incoming Relationships")
                                .foregroundStyle(.placeholder)
                        }
                    }
                }
            }
        }
    }
    
    struct MigrationTabView: View {
        @Environment(Database.self) private var database
        @Environment(\.schema) private var schema
        @State private var migrationTexts: [String: String] = [:]
        
        var body: some View {
            List {
                ForEach(Array(database.stores.values), id: \.identifier) { store in
                    Section("Migration Classifier - \(store.identifier)") {
                        if let migrationText = self.migrationTexts[store.identifier] {
                            Text(migrationText.isEmpty ? "Loading..." : migrationText)
                                .font(.system(.footnote, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .refreshable(action: refreshMigrationText)
            .task(id: schema, refreshMigrationText)
        }
        
        private func refreshMigrationText() {
            Task {
                var migrationTexts = [String: String]()
                for store in database.stores.values {
                    do {
                        if let stored = try store.getValue(forKey: "schema", as: Schema.self) {
                            #if false
                            let decision = DataStoreMigration.Classifier(from: stored, to: schema)
                            migrationTexts[store.identifier] = "\(decision.classify())"
                            #endif
                        } else {
                            migrationTexts[store.identifier] = "<error>"
                        }
                    } catch {
                        migrationTexts[store.identifier] = "<error: \(error)>"
                    }
                }
                self.migrationTexts = migrationTexts
            }
        }
    }
    
    struct RuntimeTabView: View {
        @Environment(Observer.self) private var observer
        
        var body: some View {
            List {
                Button("Clear Timeline", action: observer.clear)
                Section("Save Events") {
                    if !observer.saveEvents.isEmpty {
                        ForEach(observer.saveEvents) { event in
                            VStack(alignment: .leading, spacing: 2) {
                                let timestamp = event.timestamp.formatted(
                                    date: .abbreviated,
                                    time: .standard
                                )
                                HStack {
                                    Text("\(timestamp)")
                                    Spacer()
                                    Text("\(event.phase)")
                                        .foregroundStyle(.secondary)
                                }
                                .font(.footnote)
                                HStack {
                                    Text("Inserted: \(event.inserted.count)")
                                    Text("Updated: \(event.updated.count)")
                                    Text("Deleted: \(event.deleted.count)")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("No Save Events")
                            .foregroundStyle(.placeholder)
                    }
                }
                Section("Predicate Translations") {
                    if !observer.translations.isEmpty {
                        let translations = self.observer.translations.sorted {
                            $0.id.uuidString < $1.id.uuidString
                        }
                        ForEach(translations) { translation in
                            let key = translation.id.uuidString.prefix(8)
                            DisclosureGroup("Trace \(key) • \(translation.tree.path.count) Node(s)") {
                                VStack(alignment: .leading, spacing: 8) {
                                    if let predicateDescription = translation.predicateDescription {
                                        Text(predicateDescription)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .textSelection(.enabled)
                                    }
                                    VStack {
                                        if let predicateHash = translation.predicateHash {
                                            Text("hash: \(predicateHash)")
                                        }
                                        if let placeholdersCount = translation.placeholdersCount,
                                           let bindingsCount = translation.bindingsCount {
                                            Text("placeholders: \(placeholdersCount)")
                                            Text("bindings: \(bindingsCount)")
                                        }
                                        if let sql = translation.sql {
                                            Text(sql)
                                                .font(.system(.footnote, design: .monospaced))
                                                .textSelection(.enabled)
                                        }
                                        if !translation.tree.path.isEmpty {
                                            Divider()
                                            ForEach(
                                                Array(translation.tree.path.enumerated()),
                                                id: \.offset
                                            ) { index, node in
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Node \(index)")
                                                    Text(String(reflecting: node))
                                                        .font(.system(.footnote, design: .monospaced))
                                                        .textSelection(.enabled)
                                                }
                                                .padding(.vertical, 4)
                                            }
                                        }
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } else {
                        Text("No Predicate Translations")
                            .foregroundStyle(.placeholder)
                    }
                }
            }
        }
    }
    
    struct ScenariosTabView: View {
        @Environment(\.modelContext) private var modelContext
        @State private var scenarioOutput: String = ""
        var scenarios: [Any]
        
        var body: some View {
            EmptyView()
        }
    }
    
    struct EntityDetailView: View {
        @Environment(\.schema) private var schema
        var entity: Schema.Entity
        
        var body: some View {
            List {
                Section("Attributes") {
                    PropertiesView(properties: entity.attributes.sorted { $0.name < $1.name })
                }
                Section("Relationships") {
                    PropertiesView(properties: entity.relationships.sorted { $0.name < $1.name })
                }
                Section("Indices") {
                    if !entity.indices.isEmpty {
                        ForEach(entity.indices, id: \.self) { group in
                            Text(String(describing: group))
                                .font(.system(.footnote, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    } else {
                        Text("None").foregroundStyle(.placeholder)
                    }
                }
                Section("Uniqueness Constraints") {
                    if entity.uniquenessConstraints.isEmpty {
                        Text("None").foregroundStyle(.secondary)
                    } else {
                        ForEach(entity.uniquenessConstraints, id: \.self) { group in
                            Text(String(describing: group))
                                .font(.system(.footnote, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .navigationTitle(entity.name)
        }
    }
    
    struct PropertiesView: View {
        var properties: [any SchemaProperty]
        
        var body: some View {
            if !properties.isEmpty {
                ForEach(properties, id: \.name) { property in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(property.name)
                            Spacer()
                            Group {
                                if property.isTransient {
                                    Text("transient")
                                }
                                if property.isUnique {
                                    Text("unique")
                                }
                                Text(property.isOptional ? "optional" : "required")
                                    .foregroundStyle(property.isOptional ? Color.secondary : Color.red)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .font(.footnote)
                        HStack {
                            Text("\(String(describing: property.valueType)).self").monospaced()
                            if let defaultValue = (property as? Schema.Attribute)?.defaultValue {
                                Text("Default Value: \(String(describing: defaultValue))")
                            }
                            switch property {
                            case let attribute as Schema.Attribute:
                                ForEach(attribute.options, id: \.self) { option in
                                    switch option {
                                    case .ephemeral: Text("ephemeral")
                                    case .externalStorage: Text("external storage")
                                    default: EmptyView()
                                    }
                                }
                            case let relationship as Schema.Relationship:
                                Text(relationship.deleteRule.rawValue)
                                Text(relationship.isToOneRelationship ? "to-one" : "to-many")
                                ForEach(relationship.options, id: \.self) { option in
                                    switch option {
                                    case .unique: Text("unique")
                                    default: EmptyView()
                                    }
                                }
                            default:
                                EmptyView()
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("None").foregroundStyle(.placeholder)
            }
        }
    }
    
    struct EdgeView: View {
        var source, property: String
        var destination: String
        var deleteRule: Schema.Relationship.DeleteRule
        var isToOneRelationship: Bool
        var isOptional: Bool
        var isUnique: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                EdgeBadge(source: source, property: property, destination: destination)
                HStack {
                    Text(deleteRule.rawValue)
                    Text(isToOneRelationship ? "to-one" : "to-many")
                    Text(isOptional ? "optional" : "required")
                    Text(isUnique ? "unique" : "non-unique")
                }
                .foregroundStyle(.secondary)
            }
            .font(.footnote)
        }
    }
    
    struct EdgeBadge: View {
        var source, property: String
        var destination: String
        
        var body: some View {
            HStack {
                Text("\(source).\(property)")
                Image(systemName: "chevron.right")
                Text("\(destination)")
            }
        }
    }
}
