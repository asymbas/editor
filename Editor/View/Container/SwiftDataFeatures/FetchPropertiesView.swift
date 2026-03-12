//
//  FetchPropertiesView.swift
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
        FetchPropertiesView()
    }
}

struct FetchPropertiesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.schema) private var schema
    @State private var shouldFetchAllProperties: Bool = false
    @State private var properties: OrderedSet<PropertyMetadata> = []
    @State private var models: [any PersistentModel] = []
    @State private var isExpanded: Bool = true
    @State private var entity: Schema.Entity?
    
    var body: some View {
        List {
            Section {
                FilteredConsoleView {
                    $0.metadata?["properties_to_prefetch"] != nil ||
                    $0.metadata?["fetched_snapshots"] != nil
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
                                $0.isAttribute
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        switch properties.isEmpty {
                        case true:
                            Text("Accessing any attribute property is safe, because the snapshot has provided the backing data for it.")
                        case false:
                            Text("Executing this will cause a crash, because the values were never provided to the backing data for these properties.")
                                .foregroundStyle(.red)
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(properties, id: \.name) { property in
                                        Text(property.name)
                                            .foregroundStyle(.white)
                                            .padding(10)
                                            .background(in: .capsule)
                                            .backgroundStyle(.red.mix(with: .black, by: 0.25).opacity(0.75))
                                    }
                                }
                                .bold()
                            }
                            .scrollClipDisabled()
                        }
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    Button("Access All Properties", role: properties.isEmpty ? nil : .destructive) {
                        for model in models {
                            touchProperty(model: model, with: nil)
                        }
                    }
                    .disabled(models.isEmpty)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accesses each model's backing data for only the selected attribute properties.")
                        .font(.caption)
                        .fontWeight(.medium)
                    Button("Access Selected Properties") {
                        for model in models {
                            touchProperty(model: model, with: properties)
                        }
                    }
                    .disabled(models.isEmpty)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fetches the `\(entity?.name ?? "nil")` model's backing data for all of its properties or the selected ones.")
                        .font(.caption)
                        .fontWeight(.medium)
                    Button(
                        shouldFetchAllProperties
                        ? "Fetch All Properties"
                        : "Fetch Selected Properties: \(properties.map(\.name).joined(separator: ", "))"
                    ) {
                        do {
                            guard let type = self.entity?.type else {
                                fatalError()
                            }
                            try descriptor(type: type)
                        } catch {
                            Banner(.error, "Failure") {
                                "Failed to prefetch with to-one relationship: \(error)"
                            }
                        }
                    }
                    .disabled(entity == nil)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .toolbar {
            Toggle("Fetch All", isOn: $shouldFetchAllProperties)
        }
    }
    
    private func descriptor<T: PersistentModel>(type: T.Type) throws {
        var descriptor = FetchDescriptor<T>()
        if !shouldFetchAllProperties {
            descriptor.propertiesToFetch = properties
                .map(\.keyPath)
                .compactMap { keyPath -> (PartialKeyPath<T> & Sendable)? in
                    sendable(cast: keyPath)
                }
        }
        self.models = try modelContext.fetch(descriptor)
        logger.debug(
            "Fetched \(models.count) \(Schema.entityName(for: T.self))",
            metadata: ["properties_to_prefetch": "\(descriptor.propertiesToFetch)"]
        )
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
