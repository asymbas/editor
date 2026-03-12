//
//  Schema+VersionedSchema.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Logging
import SwiftData
import SwiftUI

struct SchemaMigrationTest: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [
            .custom(
                fromVersion: SchemaV1.self,
                toVersion: SchemaV2.self,
                willMigrate: { modelContext in
                    do {
                        let result = try modelContext.fetch(FetchDescriptor<SchemaV1.First>())
                        logger.debug("Will migrate: \(result.count)")
                    } catch {
                        logger.error("Will migrate error: \(error)")
                    }
                }, didMigrate: { context in
                    
                }
            )
        ]
    }
}

struct SchemaV1: VersionedSchema {
    static var models: [any PersistentModel.Type] { [First.self] }
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
    
    @Model class First {
        /// Explicitly annotating the macro shows up in `Schema.PropertyMetadata.metadata`.
        @Attribute var first: String
        
        init(first: String) {
            self.first = first
        }
    }
}

struct SchemaV2: VersionedSchema {
    static var models: [any PersistentModel.Type] { [Second.self] }
    static var versionIdentifier: Schema.Version { .init(2, 0, 0) }
    
    @Model class Second {
        /// Shows as `nil` in `Schema.PropertyMetadata.metadata`.
        var second: String
        
        init(second: String) {
            self.second = second
        }
    }
}
