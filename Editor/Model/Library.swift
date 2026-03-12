//
//  Library.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreSupport
import Logging
import SQLiteHandle
import SwiftUI
import Synchronization

#if swift(>=6.2)
import SwiftData
#else
@preconcurrency import SwiftData
#endif

#if canImport(Shared)
import Shared
#endif

@Observable final class Library: Sendable {
    typealias StoreIdentifier = String
    nonisolated let id: String
    nonisolated static let instances: [StoreIdentifier: Library] = [:]
    nonisolated let database: Database
    nonisolated let observer: Observer
    @MainActor var tables: [(String, [[String: any Sendable]])] = []
    @MainActor var models: [Schema.Entity: [any PersistentModel]] = [:]
    @MainActor var hasLaunched: Bool = false
    
    nonisolated init(id: String, database: Database, observer: Observer) {
        self.id = id
        self.database = database
        self.observer = observer
    }
    
    nonisolated convenience init(configuration: consuming Configuration) {
        let database = configuration.makeDatabase(&configuration)
        self.init(
            id: configuration.id,
            database: database,
            observer: configuration.observer
        )
    }
    
    deinit {
        logger.info("Library deinit: \(id)")
    }
}

struct LibrarySetup: ViewModifier {
    @Environment(Library.self) private var library
    @Environment(\.modelContext) private var modelContext
    @AppStorage("seed-sample-data") private var shouldSeedSampleData: Bool = true
    
    func body(content: Content) -> some View {
        content.task(id: library.id) {
            do {
                guard library.id == Configuration.default.id else {
                    return
                }
                if !library.hasLaunched, shouldSeedSampleData {
                    try await seedSampleData(into: modelContext)
                    library.hasLaunched = true
                    let upsert1 = Entity(id: "entity")
                    modelContext.insert(upsert1)
                    try modelContext.save()
                    let upsert2 = Entity(id: "entity")
                    modelContext.insert(upsert2)
                    try modelContext.save()
                    Banner(.ok, "Seed")
                } else {
                    modelContext.rollback()
                    logger.trace("Skipped seeding sample data at launch.")
                }
            } catch {
                Banner(.error, "Setup Error") {
                    "DataStore encountered an error: \(error)"
                }
            }
        }
    }
}

extension View {
    func dependencies(_ library: Library) -> some View {
        self
            .banners { banner in
                banner.frame(maxWidth: 500)
            }
            .loggerPreviewAttachment(isEnabled: false)
            .appearance()
            .modifier(LibrarySetup())
            .environment(Console.shared)
            .environment(library)
            .environment(library.database)
            .environment(library.observer)
            .environment(\.schema, library.database.schema)
            .modelContainer(library.database.modelContainer)
    }
}
