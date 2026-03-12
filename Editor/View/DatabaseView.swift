//
//  DatabaseView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import DataStoreRuntime
import DataStoreSQL
import DataStoreSupport
import Logging
import SQLiteHandle
import SwiftData
import SwiftUI

#if canImport(Shared)
import Shared
#endif

struct DatabaseView: View {
    @Environment(Database.self) private var database
    @Environment(Library.self) private var library
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            VStack {
                ControlSet()
                    .safeAreaPadding(Self.edges)
                ScrollView {
                    VStack {
                        LazyVStack(pinnedViews: .sectionHeaders) {
                            Section {
                                TablesDetailView()
                            } header: {
                                HeaderView(title: "Tables")
                            }
                            Divider()
                            Section {
                                ModelsDetailView()
                            } header: {
                                HeaderView(title: "Models")
                            }
                        }
                    }
                    .safeAreaPadding(.horizontal)
                }
                .refreshable {
                    Task(priority: .userInitiated) { @DatabaseActor in
                        await database.withDataStore { store in
                            let result = fetch(store.configuration)
                            await MainActor.run { library.tables = result }
                        }
                    }
                }
                .onDataStoreChange { store in
                    let result = fetch(store.configuration)
                    await MainActor.run { library.tables = result }
                }
            }
        }
        .modifier(PreviewSnapshot())
    }
    
    @MainActor static let edges: Edge.Set = {
#if os(iOS)
        [.top, .horizontal]
#elseif os(macOS)
        [
            .top, .horizontal
        ]
#else
            .init()
#endif
    }()
    
    
    
    struct PreviewSnapshot: ViewModifier {
        @State private var selectedRow: TableRowSelection?
        
        func body(content: Content) -> some View {
            content
                .selectedTableViewRow($selectedRow)
                .previewSnapshot(for: $selectedRow, makePersistentIdentifier: { selection in
                    if let selection {
                        return (selection.tableName, selection.primaryKey)
                    } else {
                        return nil
                    }
                })
        }
    }
    
    struct HeaderView: View {
        var title: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.title.weight(.bold))
                StoreTimestamp()
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sectionGradualEffect()
        }
    }
    
    struct TablesDetailView: View {
        @Environment(Database.self) private var database
        @Environment(Observer.self) private var observer
        @Environment(Library.self) private var library
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        var body: some View {
            switch !library.tables.isEmpty {
            case true:
                VStack {
                    ForEach(Array(library.tables.enumerated()), id: \.offset) { index, tables in
                        NavigationLink {
                            VStack {
                                TableView(
                                    table: tables.0,
                                    rows: tables.1,
                                    foreignKeyViolations: observer.foreignKeyViolationsByTable[tables.0] ?? [],
                                    uniqueViolations: observer.uniqueViolationsByTable[tables.0] ?? []
                                )
                            }
                            .safeAreaPadding()
                            
                        } label: {
                            TableView(
                                table: tables.0,
                                rows: tables.1,
                                foreignKeyViolations: observer.foreignKeyViolationsByTable[tables.0] ?? [],
                                uniqueViolations: observer.uniqueViolationsByTable[tables.0] ?? []
                            )
                            .column(maxWidth: horizontalSizeClass == .regular ? 800 : 200)
                            .frame(maxHeight: 200)
                            
                        }
                        .foregroundStyle(.primary)
                        .buttonStyle(.plain)
                    }
                }
            case false:
                ContentUnavailableView(
                    "No Tables",
                    systemImage: "square",
                    description: Text("SQL has no data.")
                )
            }
        }
    }
    
    struct ModelsDetailView: View {
        @Environment(Library.self) private var library
        
        var body: some View {
            switch !library.models.isEmpty {
            case true:
                ForEach(Array(library.models), id: \.key) { pair in
                    GroupBox(pair.key.name) {
                        LazyVGrid(columns: [.init(.flexible(minimum: 100, maximum: 100))]) {
                            ForEach(pair.value, id: \.persistentModelID) { model in
                                Text(String(describing: model.persistentModelID))
                            }
                        }
                    }
                }
            case false:
                ContentUnavailableView(
                    "No Models",
                    systemImage: "circle",
                    description: Text("SwiftData made no queries.")
                )
                .safeAreaPadding()
            }
        }
    }
    
    struct ControlSet: View {
        @Environment(Database.self) private var database
        @Environment(Library.self) private var library
        @Environment(\.modelContext) private var modelContext
        
        var body: some View {
            ScrollView(.horizontal) {
                HStack(spacing: Self.rowSpacing) {
                    CircleButton()
                        .buttonStyle(.borderless)
                    Divider()
                        .frame(height: 25)
                    RefreshButton()
                        .labelStyle(.iconOnly)
                    SchemaButton("Database", for: nil)
                    PredicateTreeButton()
                    #if false
                    DataStoreButton("Reset CloudKit") { store in
                        Task { try await store.cloudKitReplicator?.resetRemoteZone() }
                    }
                    DataStoreButton("Pull CloudKit") { store in
                        Task { @DatabaseActor in store.cloudKitReplicator?.pullRemoteChanges }
                    }
                    DataStoreButton("Push CloudKit") { store in
                        Task { @DatabaseActor in store.cloudKitReplicator?.pushLocalChanges }
                    }
                    #endif
                    DeleteAllButton()
                    Button("Test Entity Unique") {
                        Task {
                            modelContext.insert(Entity(id: "constraint"))
                            modelContext.insert(Entity(id: "constraint"))
                            try modelContext.save()
                        }
                    }
                    Button("Test User Unique") {
                        Task {
                            modelContext.insert(User(id: "constraint"))
                            modelContext.insert(User(id: "constraint"))
                            try modelContext.save()
                        }
                    }
                    Button("Seed Sample") {
                        Task { try await seedSampleData(into: modelContext, force: true) }
                    }
                    Button("Seed Dependency Cycle") {
                        Task { try await RelationshipSchema.seed(into: modelContext) }
                    }
                    Button("History") {
                        let descriptor = HistoryDescriptor<DatabaseHistoryTransaction>()
                        let history = try! modelContext.fetchHistory(descriptor)
                        logger.debug("DatabaseHistoryTransaction: \(history)")
                        for transaction in history {
                            for change in transaction.changes {
                                switch change {
                                case .insert(let history): logger.info("Insert: \(history)")
                                case .update(let history): logger.info("Update: \(history)")
                                case .delete(let history): logger.info("Delete: \(history)")
                                @unknown default: fatalError()
                                }
                            }
                        }
                    }
                    Button("Create Snapshot") {
                        if let model = try? modelContext.fetch(all: User.self).first {
                            let snapshot = DatabaseSnapshot(model)
                            var relatedSnapshots = [PersistentIdentifier: DatabaseSnapshot]()
                            var remappedIdentifiers = [PersistentIdentifier: PersistentIdentifier]()
                            let newModel = try! User(
                                snapshot,
                                relatedSnapshots: &relatedSnapshots,
                                remappedIdentifiers: &remappedIdentifiers,
                                modelContext: modelContext
                            )
                            modelContext.insert(newModel)
                            Banner("Done") {
                                """
                                Created a snapshot from model and reinitialized.
                                Completed: \(newModel)
                                """
                            }
                            try? modelContext.save()
                        }
                    }
                }
                .scrollTargetLayout()
                .fontWeight(.semibold)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.never)
            .scrollClipDisabled()
            .buttonStyle(.borderedProminent)
            
        }
        
        @MainActor private static var rowSpacing: CGFloat? = {
            #if os(macOS)
            5
            #else
            nil
            #endif
        }()
        
        struct CircleButton: View {
            @AppStorage("appearance") private var appearance: Appearance = .automatic
            
            @MainActor private static let size: CGFloat = {
                #if os(iOS)
                25
                #else
                15
                #endif
            }()
            
            var body: some View {
                Button(action: { appearance = appearance.cycle }) {
                    ZStack {
                        Circle()
                            .fill(
                                Color(
                                    red: .random(in: 0...1),
                                    green: .random(in: 0...1),
                                    blue: .random(in: 0...1)
                                )
                            )
                            .frame(width: Self.size)
                        if appearance == .automatic {
                            Circle()
                            
                                .strokeBorder(Color.accentColor.opacity(0.8), lineWidth: 2)
                                .frame(width: Self.size + 10)
                        }
                    }
                    .frame(width: Self.size + 10, height: Self.size + 10)
                }
                .buttonStyle(.plain)
                .onChange(of: appearance) { _, newValue in
                    Banner { "Appearance: \(newValue.rawValue.capitalized)" }
                }
            }
        }
        
        struct DeleteAllButton: View {
            @Environment(\.modelContext) private var modelContext
            @Environment(\.schema) private var schema
            
            var body: some View {
                Button("Delete All") {
                    guard let type = self.schema.types.randomElement() else {
                        fatalError()
                    }
                    do {
                        try modelContext.delete(model: type)
                        try modelContext.save()
                        Banner(.info, "Success") {
                            "Deleted `\(type).self`."
                        }
                    } catch {
                        Banner(.error, "Delete Error") {
                            "Unable to delete `\(type).self`: \(error)"
                        }
                    }
                }
            }
        }
    }
}
