//
//  DatabaseFetch.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftData
import SwiftUI

@MainActor class DatabaseFetch: Sendable {
    private var fetch: @MainActor (ModelContext) throws -> [DatabaseRecord]
    let title: String
    let systemImage: String
    
    @MainActor init<Model: PersistentModel>(
        schema: Schema? = nil,
        _ title: String,
        systemImage: String? = nil,
        model: Model.Type,
        descriptor: @escaping @MainActor (ModelContext) -> FetchDescriptor<Model>
    ) {
        self.title = title
        self.systemImage = systemImage
        ?? (Model.self as? any SystemImageNameProviding.Type)?.systemImage
        ?? "circle"
        self.fetch = { modelContext in
            let schema = schema ?? Schema([Model.self])
            return try modelContext.fetch(descriptor(modelContext)).compactMap {
                guard let entity = schema.entity(for: Model.self) else {
                    return nil
                }
                return DatabaseRecord(model: $0, entity: entity)
            }
        }
    }
    
    @MainActor convenience init<Model: PersistentModel>(
        schema: Schema? = nil,
        _ title: String,
        systemImage: String? = nil,
        model: Model.Type
    ) {
        self.init(schema: schema, title, systemImage: systemImage, model: model) { _ in
            FetchDescriptor<Model>()
        }
    }
    
    func run(in modelContext: ModelContext) throws -> [DatabaseRecord] {
        try fetch(modelContext)
    }
}
