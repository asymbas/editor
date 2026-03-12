//
//  Database.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreCore
import DataStoreKit
import DataStoreRuntime
import DataStoreSQL
import DataStoreSupport
import Logging
import SQLiteHandle
import SQLiteStatement
import SwiftUI

#if swift(>=6.2)
import SwiftData
#else
@preconcurrency import SwiftData
extension Schema: @unchecked Sendable {}
#endif

#if canImport(SwiftUI)
extension Database: Observable {}
#endif

@DatabaseActor final class Database: AnyObject, Sendable {
    nonisolated let stores: [String: DatabaseStore]
    nonisolated let modelContainer: ModelContainer
    nonisolated let modelExecutor: any ModelExecutor
    #if swift(>=6.2)
    nonisolated weak let attachment: (any DataStoreDelegate)?
    #else
    nonisolated(unsafe) weak var attachment: (any DataStoreDelegate)?
    #endif
    nonisolated let schema: Schema
    
    @MainActor lazy var view: (any DataStoreObservable)? = {
        attachment as? any DataStoreObservable
    }()
    
    var modelContext: ModelContext {
        (modelExecutor as? DefaultDatabaseSerialModelExecutor).unsafelyUnwrapped.modelContext
    }
    
    var editingState: EditingState {
        modelContext.editingState
    }
    
    nonisolated required init(
        schema: Schema,
        configurations: [any DataStoreConfiguration],
        modelContainer: ModelContainer,
        attachment: (any DataStoreDelegate)? = nil
    ) throws {
        self.schema = schema
        self.modelContainer = modelContainer
        self.modelExecutor = DefaultDatabaseSerialModelExecutor(modelContext: .init(modelContainer))
        var resolvedAttachment: (any DataStoreDelegate)? = attachment
        self.stores = configurations.reduce(into: .init()) { partialResult, configuration in
            guard let configuration = configuration as? DatabaseConfiguration else {
                return
            }
            if let configurationAttachment = configuration.attachment {
                if let resolved = resolvedAttachment {
                    if resolved !== configurationAttachment { fatalError() }
                } else {
                    resolvedAttachment = configurationAttachment
                }
            }
            if let store = configuration.store {
                partialResult[store.identifier] = store
            }
        }
        self.attachment = resolvedAttachment
    }
    
    nonisolated convenience init(
        schema: Schema,
        configurations: [any DataStoreConfiguration]
    ) {
        do {
            let modelContainer = try ModelContainer(for: schema, configurations: configurations)
            try self.init(schema: schema, configurations: configurations, modelContainer: modelContainer, attachment: nil)
        } catch SwiftDataError.loadIssueModelContainer {
            fatalError()
        } catch {
            fatalError("Database error: \(error)")
        }
    }
    
    nonisolated convenience init() {
        self.init(schema: .init(), configurations: [DatabaseConfiguration()])
    }
    
    deinit {
        logger.debug("Database deinit: \(stores)")
    }
    
    func save() async throws {
        if modelContext.hasChanges { try modelContext.save() }
    }
    
    func fetchCount<T>(_ descriptor: FetchDescriptor<T>) throws -> Int
    where T: PersistentModel {
        try modelContext.fetchCount(descriptor)
    }
    
    func fetchIdentifiers<T>(_ descriptor: FetchDescriptor<T>) throws -> [PersistentIdentifier]
    where T: PersistentModel {
        try modelContext.fetchIdentifiers(descriptor)
    }
    
    struct DatabaseSnapshotSet: Sendable {
        var snapshot: DatabaseSnapshot
        var relatedSnapshots: [PersistentIdentifier: DatabaseSnapshot]
    }
    
    enum Error: Swift.Error {
        case modelNotFound
    }
}

extension Database {
    func withDataStore<T>(
        identifier: String? = nil,
        storeHandler: @escaping (sending DatabaseStore) async throws -> T?
    ) async rethrows -> T? where T: Sendable {
        if let identifier, let store = self.stores[identifier] {
            return try await storeHandler(store)
        } else {
            var result: T?
            for (_, store) in stores {
                if let value = try await storeHandler(store) { result = value }
            }
            return result
        }
    }
    
    func _withDataStore<T>(
        identifier: String? = nil,
        storeHandler: @escaping (sending DatabaseStore) async throws -> T?
    ) async rethrows -> [T] where T: Sendable {
        if let identifier, let store = self.stores[identifier] {
            if let value = try await storeHandler(store) {
                return [value]
            }
            return []
        } else {
            var results = [T]()
            for (_, store) in stores {
                if let value = try await storeHandler(store) {
                    results.append(value)
                }
            }
            return results
        }
    }
    
    func fetch<T>(_ descriptor: FetchDescriptor<T>)
    async throws -> [DatabaseSnapshot] where T: PersistentModel {
        var snapshots = [DatabaseSnapshot]()
        for (_, store) in stores {
            let result: DatabaseFetchResult = try store.fetch(DatabaseFetchRequest(
                descriptor: descriptor,
                editingState: .init(id: editingState.id, author: editingState.author)
            ))
            snapshots.append(contentsOf: result.fetchedSnapshots)
        }
        return snapshots
    }
    
    func snapshot(for persistentIdentifier: PersistentIdentifier)
    async throws -> DatabaseSnapshot? {
        var relatedSnapshots: [PersistentIdentifier: DatabaseSnapshot]? = .init()
        return await withDataStore(identifier: persistentIdentifier.storeIdentifier) { store in
            if let entity = store.schema.entitiesByName[persistentIdentifier.entityName],
               let snapshot = try? store.fetch(
                for: persistentIdentifier.primaryKey(),
                entity: entity,
                relatedSnapshots: &relatedSnapshots
               ) {
                return snapshot
            } else {
                return nil
            }
        }
    }
    
    func snapshot(for persistentIdentifier: PersistentIdentifier)
    async throws -> DatabaseSnapshotSet? {
        var relatedSnapshots: [PersistentIdentifier: DatabaseSnapshot] = .init()
        return try await withDataStore(identifier: persistentIdentifier.storeIdentifier) { store in
            let primaryKey = persistentIdentifier.primaryKey()
            let result = try store.queue.reader { connection in
                try connection.fetch {
                    "SELECT * FROM \(quote(persistentIdentifier.entityName))"
                    Where("\(quote("pk")) = ?", bindings: primaryKey)
                    Limit(1)
                }
            }
            guard let row = result.first else {
                throw Error.modelNotFound
            }
            guard let type = Schema.type(for: persistentIdentifier.entityName) else {
                fatalError()
            }
            let properties = [.discriminator(for: type)] + type.databaseSchemaMetadata
            let values = row
            let snapshot = try DatabaseSnapshot(
                store: store,
                registry: store.manager.registry(for: self.modelContext.editingState),
                properties: .init(properties),
                values: .init(values),
                relatedSnapshots: &relatedSnapshots
            )
            return .init(snapshot: snapshot, relatedSnapshots: relatedSnapshots)
        }
    }
}
