//
//  SwiftDataSync.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Combine
import DataStoreKit
import Foundation
import SwiftData
import SwiftUI

#if canImport(Shared)
import Shared
#endif

#Preview {
    NavigationStack {
        SyncTestView()
    }
}

extension String {
    nonisolated static var syncToken: Self {
        "sync-token"
    }
}

@Model final class SyncItem {
    @Attribute(.unique, .preserveValueOnDeletion) var id: UUID
    var name: String
    var counter: Int
    var updatedAt: Date
    
    init(
        id: UUID = .init(),
        name: String,
        counter: Int,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.counter = counter
        self.updatedAt = updatedAt
    }
    
    struct Payload: Sendable, Hashable {
        var id: UUID
        var name: String
        var counter: Int
        var updatedAt: Date
    }
}

@MainActor @Observable private final class Model {
    private let engine: OneWayHistorySyncEngine
    let sourceModelContainer: ModelContainer
    let destinationModelContainer: ModelContainer
    var lastResultText: String = "No Sync Yet"
    var lastTokenStored: Bool = false
    
    init() {
        let schema = Schema([SyncItem.self])
        let configurationA = DatabaseConfiguration(
            transient: (),
            types: [SyncItem.self],
            schema: schema
        )
        let configurationB = DatabaseConfiguration(
            transient: (),
            types: [SyncItem.self],
            schema: schema
        )
        self.sourceModelContainer = try! ModelContainer(
            for: SyncItem.self,
            configurations: configurationA
        )
        self.destinationModelContainer = try! ModelContainer(
            for: SyncItem.self,
            configurations: configurationB
        )
        sourceModelContainer.mainContext.autosaveEnabled = false
        sourceModelContainer.mainContext.author = "source-ui"
        destinationModelContainer.mainContext.autosaveEnabled = false
        destinationModelContainer.mainContext.author = "destination-ui"
        let initialToken = Self.loadToken(forKey: .syncToken)
        self.engine = OneWayHistorySyncEngine(
            source: sourceModelContainer,
            destination: destinationModelContainer,
            sourceAuthor: "source-ui",
            destinationAuthor: "sync-engine",
            initialToken: initialToken
        )
    }
    
    func syncNow() async {
        do {
            let result = try await engine.sync()
            self.lastResultText = "Upserts: \(result.appliedUpserts) | Deletes: \(result.appliedDeletes) | Transactions: \(result.processedTransactions)"
            if let token = result.newToken {
                Self.saveToken(token, forKey: .syncToken)
                self.lastTokenStored = true
            } else {
                self.lastTokenStored = false
            }
        } catch {
            self.lastResultText = "Sync Failed: \(error)"
            self.lastTokenStored = false
        }
    }
    
    func clearToken() async {
        await engine.setToken(nil)
        UserDefaults.standard.removeObject(forKey: .syncToken)
        self.lastTokenStored = false
        self.lastResultText = "Token Cleared"
    }
    
    private static func loadToken(forKey key: String) -> DatabaseHistoryToken? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(DatabaseHistoryToken.self, from: data)
    }
    
    private static func saveToken(_ token: DatabaseHistoryToken, forKey key: String) {
        let data = try? JSONEncoder().encode(token)
        UserDefaults.standard.set(data, forKey: key)
    }

    enum SyncDelta: Hashable, Sendable {
        case upsert(SyncItem.Payload)
        case delete(UUID)
    }

    struct SyncResult: Hashable, Sendable {
        var appliedUpserts: Int
        var appliedDeletes: Int
        var processedTransactions: Int
        var newToken: DatabaseHistoryToken?
    }
    
    actor OneWayHistorySyncEngine {
        private let sourceModelContainer: ModelContainer
        private let destinationModelContainer: ModelContainer
        private let sourceAuthor: String
        private let destinationAuthor: String
        private var lastToken: DatabaseHistoryToken?
        
        init(
            source sourceModelContainer: ModelContainer,
            destination destinationModelContainer: ModelContainer,
            sourceAuthor: String = "source-ui",
            destinationAuthor: String = "sync-engine",
            initialToken: DatabaseHistoryToken? = nil
        ) {
            self.sourceModelContainer = sourceModelContainer
            self.destinationModelContainer = destinationModelContainer
            self.sourceAuthor = sourceAuthor
            self.destinationAuthor = destinationAuthor
            self.lastToken = initialToken
        }
        
        func currentToken() -> DatabaseHistoryToken? {
            lastToken
        }
        
        func setToken(_ token: DatabaseHistoryToken?) {
            lastToken = token
        }
        
        func sync() throws -> SyncResult {
            do {
                if let token = self.lastToken {
                    return try historySync(after: token)
                } else {
                    return try snapshotSyncAndAdvanceToken()
                }
            } catch let error as SwiftDataError {
                switch error {
                case .historyTokenExpired:
                    self.lastToken = nil
                    return try snapshotSyncAndAdvanceToken()
                default:
                    throw error
                }
            }
        }
        
        private func historySync(after token: DatabaseHistoryToken) throws -> SyncResult {
            let sourceModelContext = ModelContext(sourceModelContainer)
            sourceModelContext.autosaveEnabled = false
            var descriptor = HistoryDescriptor<DatabaseHistoryTransaction>()
            descriptor.predicate = #Predicate { transaction in
                transaction.token > token && transaction.author != destinationAuthor
            }
            let transactions = try sourceModelContext.fetchHistory(descriptor)
            if transactions.isEmpty {
                return .init(
                    appliedUpserts: 0,
                    appliedDeletes: 0,
                    processedTransactions: 0,
                    newToken: token
                )
            }
            var deltas = [SyncDelta]()
            deltas.reserveCapacity(transactions.reduce(into: 0) { $0 += $1.changes.count })
            for transacton in transactions {
                for change in transacton.changes {
                    switch change {
                    case
                            .insert(_ as DatabaseHistoryInsert<SyncItem>),
                            .update(_ as DatabaseHistoryUpdate<SyncItem>):
                        if let model = try fetchSyncItem(
                            in: sourceModelContext,
                            persistentIdentifier: change.changedPersistentIdentifier
                        ) {
                            deltas.append(.upsert(.init(
                                id: model.id,
                                name: model.name,
                                counter: model.counter,
                                updatedAt: model.updatedAt
                            )))
                        }
                    case .delete(let deletion as DatabaseHistoryDelete<SyncItem>):
                        if let deletedID: UUID = deletion[\SyncItem.id] as? UUID {
                            deltas.append(.delete(deletedID))
                        }
                        #if false
                        if let deletedID: UUID = deletion.tombstone[\SyncItem.id] as? UUID {
                            deltas.append(.delete(deletedID))
                        }
                        #endif
                    default:
                        break
                    }
                }
            }
            let destinationModelContext = ModelContext(destinationModelContainer)
            destinationModelContext.autosaveEnabled = false
            destinationModelContext.author = self.destinationAuthor
            let applied = try apply(deltas: deltas, in: destinationModelContext)
            try destinationModelContext.save()
            let newToken = transactions.last?.token ?? token
            self.lastToken = newToken
            return .init(
                appliedUpserts: applied.upserts,
                appliedDeletes: applied.deletes,
                processedTransactions: transactions.count,
                newToken: newToken
            )
        }
        
        private func snapshotSyncAndAdvanceToken() throws -> SyncResult {
            let sourceModelContext = ModelContext(sourceModelContainer)
            sourceModelContext.autosaveEnabled = false
            let sourceModels = try sourceModelContext.fetch(FetchDescriptor<SyncItem>())
            let sourceIdentifiers = Set(sourceModels.map(\.id))
            let destinationModelContext = ModelContext(destinationModelContainer)
            destinationModelContext.autosaveEnabled = false
            destinationModelContext.author = self.destinationAuthor
            let destinationModels = try destinationModelContext.fetch(FetchDescriptor<SyncItem>())
            var deletes = 0
            for destinationModel in destinationModels where !sourceIdentifiers.contains(destinationModel.id) {
                destinationModelContext.delete(destinationModel)
                deletes += 1
            }
            var upserts = 0
            for sourceModel in sourceModels {
                if let existing = try fetchSyncItem(
                    in: destinationModelContext,
                    byStableID: sourceModel.id
                ) {
                    existing.name = sourceModel.name
                    existing.counter = sourceModel.counter
                    existing.updatedAt = sourceModel.updatedAt
                } else {
                    destinationModelContext.insert(SyncItem(
                        id: sourceModel.id,
                        name: sourceModel.name,
                        counter: sourceModel.counter,
                        updatedAt: sourceModel.updatedAt
                    ))
                }
                upserts += 1
            }
            try destinationModelContext.save()
            let newToken = try latestToken(in: sourceModelContext)
            self.lastToken = newToken
            return .init(
                appliedUpserts: upserts,
                appliedDeletes: deletes,
                processedTransactions: 0,
                newToken: newToken
            )
        }
        
        private func latestToken(in modelContext: ModelContext) throws -> DatabaseHistoryToken? {
            let descriptor = HistoryDescriptor<DatabaseHistoryTransaction>()
            let transactions = try modelContext.fetchHistory(descriptor)
            return transactions.last?.token
        }
        
        private func fetchSyncItem(
            in modelContext: ModelContext,
            persistentIdentifier: PersistentIdentifier
        ) throws -> SyncItem? {
            var descriptor = FetchDescriptor<SyncItem>(predicate: #Predicate {
                $0.persistentModelID == persistentIdentifier
            })
            descriptor.fetchLimit = 1
            return try modelContext.fetch(descriptor).first
        }
        
        private func fetchSyncItem(
            in modelContext: ModelContext,
            byStableID id: UUID
        ) throws -> SyncItem? {
            var descriptor = FetchDescriptor<SyncItem>(
                predicate: #Predicate { $0.id == id }
            )
            descriptor.fetchLimit = 1
            return try modelContext.fetch(descriptor).first
        }
        
        private func apply(deltas: [SyncDelta], in modelContext: ModelContext)
        throws -> (upserts: Int, deletes: Int) {
            var upserts = 0
            var deletes = 0
            for delta in deltas {
                switch delta {
                case .upsert(let payload):
                    if let existing = try fetchSyncItem(
                        in: modelContext,
                        byStableID: payload.id
                    ) {
                        existing.name = payload.name
                        existing.counter = payload.counter
                        existing.updatedAt = payload.updatedAt
                    } else {
                        modelContext.insert(SyncItem(
                            id: payload.id,
                            name: payload.name,
                            counter: payload.counter,
                            updatedAt: payload.updatedAt
                        ))
                    }
                    upserts += 1
                case .delete(let id):
                    if let existing = try fetchSyncItem(in: modelContext, byStableID: id) {
                        modelContext.delete(existing)
                        deletes += 1
                    }
                }
            }
            return (upserts, deletes)
        }
    }
}

struct SyncTestView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var model: Model = .init()
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    StorePanelView(title: "Source", isSource: true)
                        .modelContainer(model.sourceModelContainer)
                        .environment(model)
                    Divider()
                    StorePanelView(title: "Destination", isSource: false)
                        .modelContainer(model.destinationModelContainer)
                        .environment(model)
                }
            } else {
                VStack(spacing: 0) {
                    StorePanelView(title: "Source", isSource: true)
                        .modelContainer(model.sourceModelContainer)
                        .environment(model)
                    Divider()
                    StorePanelView(title: "Destination", isSource: false)
                        .modelContainer(model.destinationModelContainer)
                        .environment(model)
                }
            }
        }
        .navigationTitle("History Sync")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Sync") {
                    Task { await model.syncNow() }
                }
                Button("Clear Token") {
                    Task { await model.clearToken() }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.lastResultText)
                    .font(.footnote)
                    .lineLimit(2)
                Text(model.lastTokenStored ? "Token Stored" : "Token Not Stored")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }
    
    struct StorePanelView: View {
        @Environment(Model.self) private var playground
        @Environment(\.modelContext) private var modelContext
        @Query(sort: \SyncItem.updatedAt, order: .reverse) private var models: [SyncItem]
        let title: String
        let isSource: Bool
        
        var body: some View {
            List {
                if isSource {
                    Section {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10),
                            ],
                            spacing: 10
                        ) {
                            Button("Random Insert") { randomInsert() }
                                .buttonStyle(.bordered)
                                .frame(maxWidth: .infinity)
                            Button("Random Update") { randomUpdate() }
                                .buttonStyle(.bordered)
                                .frame(maxWidth: .infinity)
                            Button("Random Delete") { randomDelete() }
                                .buttonStyle(.bordered)
                                .frame(maxWidth: .infinity)
                            Button("Clear") { clearAll() }
                                .buttonStyle(.bordered)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 4)
                    }
                }
                Section {
                    ForEach(models) { model in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.name).font(.body)
                            HStack(spacing: 10) {
                                Text(model.id.uuidString)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Text("Count: \(model.counter)")
                                    .font(.caption)
                                    .monospacedDigit()
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    HStack {
                        Text(title).font(.headline)
                        Spacer()
                        Text("\(models.count)")
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        
        private func randomInsert() {
            let index = Int.random(in: 1...9999)
            let model = SyncItem(
                name: "Item \(index)",
                counter: Int.random(in: 0...50),
                updatedAt: .now
            )
            modelContext.insert(model)
            try? modelContext.save()
            Banner("Inserted") {
                "\(model.name) (ID: \(model.id.uuidString))"
            }
        }
        
        private func randomUpdate() {
            guard let model = self.models.randomElement() else { return }
            model.counter += Int.random(in: 1...5)
            model.updatedAt = .now
            model.name = "Item \(Int.random(in: 1...9999))"
            try? modelContext.save()
            Banner("Updated") {
                "\(model.name) (ID: \(model.id.uuidString))"
            }
        }
        
        private func randomDelete() {
            guard let model = self.models.randomElement() else { return }
            modelContext.delete(model)
            try? modelContext.save()
            Banner("Deleted") {
                "\(model.name) (ID: \(model.id.uuidString))"
            }
        }
        
        private func clearAll() {
            for model in models { modelContext.delete(model) }
            try? modelContext.save()
        }
    }
}
