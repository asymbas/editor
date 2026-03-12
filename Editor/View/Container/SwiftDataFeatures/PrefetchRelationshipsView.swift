//
//  PrefetchRelationshipsView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Collections
import DataStoreRuntime
import Logging
import SwiftData
import SwiftUI

#if canImport(Shared)
import Shared
#endif

#Preview(traits: .defaultData) {
    NavigationStack {
        PrefetchRelationshipsView()
    }
}

struct PrefetchRelationshipsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.schema) private var schema
    @State private var shouldPrefetch: Bool = true
    @State private var properties: OrderedSet<PropertyMetadata> = []
    @State private var models: [any PersistentModel] = []
    @State private var isExpanded: Bool = true
    @State private var entity: Schema.Entity?
    
    var body: some View {
        List {
            Section {
                FilteredConsoleView {
                    $0.metadata?["prefetch"] != nil ||
                    (
                        $0.metadata?["fetched_snapshots"] != nil &&
                        $0.metadata?["related_snapshots"] != "0"
                    )
                }
                .frame(height: 300)
                VStack(alignment: .leading, spacing: 15) {
                    DisclosureGroup("Picker", isExpanded: $isExpanded) {
                        EntityPicker(selection: $entity) { entity in
                            Text(entity.name)
                                .tag(entity)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        } label: {
                            Label(
                                self.entity == nil ? "Select an Entity..." : "Fetching",
                                systemImage: self.entity == nil
                                ? "questionmark.circle"
                                : "magnifyingglass.circle"
                            )
                            .fontWeight(.medium)
                            .foregroundStyle(.primary, self.entity == nil ? .yellow : .secondary)
                        }
                        if let entity = self.entity {
                            PropertyPicker(selection: $properties, entity: entity) {
                                $0.isRelationship
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accessing the relationship should not fault.")
                        .font(.caption)
                        .fontWeight(.medium)
                    Button("Access All Properties") {
                        for model in models {
                            touchProperty(model: model, with: nil)
                        }
                    }
                    .disabled(models.isEmpty)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Makes a fetch request for `\(entity?.name ?? "nil")` models where the relationships are also included with the result (as related models).")
                        .font(.caption)
                        .fontWeight(.medium)
                    Group {
                        Button(
                            shouldPrefetch
                            ? "Fetch"
                            : "Fetch with Include Related Models: \(properties.map(\.name).joined(separator: ", "))"
                        ) {
                            do {
                                guard let type = self.entity?.type else {
                                    fatalError()
                                }
                                let result = try descriptor(type: type)
                                logger.debug("Fetched \(result.count) \(Schema.entityName(for: type))", metadata: ["prefetch": "selected"])
                                self.models = result
                            } catch {
                                Banner(.error, "Failure") {
                                    "Failed to prefetch with to-one relationship: \(error)"
                                }
                            }
                        }
                        Button("\(shouldPrefetch ? "Prefetch": "Fetch") with To-One Relationship") {
                            do {
                                guard let type = self.entity?.type else {
                                    fatalError()
                                }
                                let properties = type.databaseSchemaMetadata.filter {
                                    $0.isToOneRelationship
                                }
                                self.properties = OrderedSet(properties)
                                let result = try descriptor(type: type)
                                logger.debug("Fetched \(result.count) \(Schema.entityName(for: type))", metadata: ["prefetch": "to-one"])
                                self.models = result
                            } catch {
                                Banner(.error, "Failure") {
                                    "Failed to prefetch with to-one relationship: \(error)"
                                }
                            }
                        }
                        Button("\(shouldPrefetch ? "Prefetch": "Fetch") with To-Many Relationship") {
                            do {
                                guard let type = self.entity?.type else {
                                    fatalError()
                                }
                                let properties = type.databaseSchemaMetadata.filter {
                                    !$0.isToOneRelationship
                                }
                                self.properties = OrderedSet(properties)
                                let result = try descriptor(type: type)
                                logger.debug("Fetched \(result.count) \(Schema.entityName(for: type))", metadata: ["prefetch": "to-many"])
                                self.models = result
                            } catch {
                                Banner(.error, "Failure") {
                                    "Failed to prefetch with to-many relationship: \(error)"
                                }
                            }
                        }
                    }
                    .disabled(entity == nil)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .toolbar {
            Toggle("Prefetch", isOn: $shouldPrefetch)
        }
    }
    
    private func descriptor<T: PersistentModel>(type: T.Type) throws -> [T] {
        var descriptor = FetchDescriptor<T>()
        if !shouldPrefetch {
            descriptor.propertiesToFetch = properties
                .map(\.keyPath)
                .compactMap { keyPath -> (PartialKeyPath<T> & Sendable)? in
                    sendable(cast: keyPath)
                }
        }
        return try modelContext.fetch(descriptor)
    }
    
    private func touchProperty<T>(
        model: T,
        with properties: OrderedSet<PropertyMetadata>?
    ) where T: PersistentModel {
        for property in properties ?? OrderedSet(T.databaseSchemaMetadata) {
            guard let keyPath = property.keyPath as? PartialKeyPath<T> else {
                fatalError()
            }
            logger.debug(
                "Key path will touch \(T.self) model property.",
                metadata: [
                    "properties_to_prefetch": "_",
                    "property": "\(property)",
                    "key_path": "\(keyPath)"
                ]
            )
            _ = model[keyPath: keyPath]
        }
    }
}
