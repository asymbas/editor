//
//  Configuration.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import Foundation

struct Configuration: CaseIterable, Equatable, Hashable, RawRepresentable {
    nonisolated let makeDatabase: @Sendable (inout Configuration) -> Database
    nonisolated let id: String
    nonisolated let types: [any (PersistentModel & SendableMetatype).Type]
    nonisolated let schema: Schema
    
    lazy var observer: Observer = {
        .init(schema: schema)
    }()
    
    nonisolated var rawValue: String {
        id
    }
    
    nonisolated init?(rawValue: RawValue) {
        switch Self.allCases.first(where: { $0.rawValue == rawValue }) {
        case let configuration?: self = configuration
        default: return nil
        }
    }
    
    nonisolated init(
        id: String,
        types: [any (PersistentModel & SendableMetatype).Type],
        schema: Schema? = nil,
        makeDatabase: @escaping @Sendable (inout Configuration) -> Database
    ) {
        self.id = id
        self.types = types
        self.schema = schema ?? .init(types)
        self.makeDatabase = makeDatabase
    }
    
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Configuration {
    static var allCases: Set<Self> {
        [.default, .migration, .transient, .versionedMigration]
    }
    
    static var `default`: Self {
        .init(
            id: "default",
            types: DefaultSchema.models,
            schema: Schema(versionedSchema: DefaultSchema.self),
            makeDatabase: { configuration in
                    .init(
                        schema: configuration.schema,
                        configurations: [
                            DatabaseConfiguration(
                                name: configuration.id,
                                types: configuration.types,
                                schema: configuration.schema,
                                url: .temporaryDirectory.appending(component: configuration.id),
                                options: [.eraseDatabaseOnSetup],
                                attachment: configuration.observer
                            )
                        ]
                    )
            }
        )
    }
    
    static var migration: Self {
        .init(
            id: "migration",
            types: MigrationSchemaV2.models,
            schema: Schema(versionedSchema: MigrationSchemaV2.self),
            makeDatabase: { configuration in
                let oldSchema =  Schema(versionedSchema: MigrationSchemaV1.self)
                _ = try! ModelContainer(
                    for: oldSchema,
                    configurations: [
                        DatabaseConfiguration(
                            name: configuration.id,
                            types: MigrationSchemaV1.models,
                            schema: oldSchema,
                            options: [.eraseDatabaseOnSetup, .disablePersistentHistoryTracking],
                            attachment: configuration.observer
                        )
                    ]
                )
                return .init(
                        schema: configuration.schema,
                        configurations: [
                            DatabaseConfiguration(
                                name: configuration.id,
                                types: configuration.types,
                                schema: configuration.schema,
                                options: [.disablePersistentHistoryTracking],
                                attachment: configuration.observer
                            )
                        ]
                    )
            }
        )
    }
    
    static var _migration: Self {
        .init(
            id: "migration",
            types: MigrationSchema.Active.models,
            schema: Schema(versionedSchema: MigrationSchema.Active.self),
            makeDatabase: { configuration in
                    .init(
                        schema: Schema(versionedSchema: MigrationSchema.Active.self),
                        configurations: [
                            DatabaseConfiguration(
                                name: configuration.id,
                                types: configuration.types,
                                schema: configuration.schema,
//                                options: [.eraseDatabaseOnSetup],
                                options: [.disablePersistentHistoryTracking],
                                attachment: configuration.observer
                            )
                        ]
                    )
            }
        )
    }
    
    static var versionedMigration: Self {
        .init(
            id: "versioned-migration",
            types: SchemaV2.models,
            schema: Schema(versionedSchema: SchemaV2.self),
            makeDatabase: { configuration in
                    .init(
                        schema: Schema(versionedSchema: SchemaV2.self),
                        configurations: [
                            DatabaseConfiguration(
                                name: configuration.id,
                                types: configuration.types,
                                schema: configuration.schema,
                                options: [.eraseDatabaseOnSetup],
                                attachment: configuration.observer
                            )
                        ]
                    )
            }
        )
    }
    
    static var transient: Self {
        .init(
            id: "transient",
            types: [],
            makeDatabase: { configuration in
                .init(
                    schema: configuration.schema,
                    configurations: [DatabaseConfiguration()]
                )
            }
        )
    }
    
    static let shared: Self = {
        .init(
            id: "shared",
            types: DefaultSchema.models,
            makeDatabase: { configuration in
                    .init(
                        schema: configuration.schema,
                        configurations: [DatabaseConfiguration()]
                    )
            }
        )
    }()
}
