//
//  SchemaButton.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import SwiftData
import SwiftUI

struct SchemaButton: View {
    @Environment(\.configurator) private var configurator
    private var title: Text
    private var icon: Image?
    private var configuration: Configuration?
    
    init(_ title: String, systemImage: String? = nil, for configuration: Configuration?) {
        self.title = Text(LocalizedStringKey(title))
        self.icon = systemImage.map(Image.init(systemName:))
        self.configuration = configuration
    }
    
    var body: some View {
        Button {
            withAnimation(.spring) {
                configurator.change(to: configuration)
            }
        } label: {
            Label {
                title
            } icon: {
                icon
            }
        }
    }
}

struct SchemaCandidate: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let modelTypes: [any PersistentModel.Type]
    
    init(id: String, title: String, modelTypes: [any PersistentModel.Type]) {
        self.id = id
        self.title = title
        self.modelTypes = modelTypes
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func versioned(
        _ schemaType: any VersionedSchema.Type,
        title: String? = nil
    ) -> Self {
        .init(
            id: String(reflecting: schemaType),
            title: title ?? String(describing: schemaType),
            modelTypes: schemaType.models
        )
    }
    
    static func models(
        _ title: String,
        _ modelTypes: [any PersistentModel.Type]
    ) -> Self {
        .init(
            id: title,
            title: title,
            modelTypes: modelTypes
        )
    }
}

struct SchemaMultiSelectorView: View {
    @Environment(\.configurator) private var configurator
    @State private var enabledSchemaIdentifiers: Set<String> = []
    @State private var enabledModelKeys: Set<String> = []
    private let candidates: [SchemaCandidate]
    private let version: Schema.Version
    
    init(
        candidates: [SchemaCandidate],
        version: Schema.Version = .init(1, 0, 0)
    ) {
        self.candidates = candidates
        self.version = version
    }
    
    var body: some View {
        List {
            Section {
                ForEach(candidates) { candidate in
                    Toggle(
                        candidate.title,
                        isOn: Binding(
                            get: { enabledSchemaIdentifiers.contains(candidate.id) },
                            set: { isEnabled in
                                if isEnabled {
                                    enabledSchemaIdentifiers.insert(candidate.id)
                                } else {
                                    enabledSchemaIdentifiers.remove(candidate.id)
                                }
                                self.enabledModelKeys = allModelKeysForEnabledSchemas()
                            }
                        )
                    )
                }
            } header: {
                HStack {
                    Text("Schemas")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("All") {
                        self.enabledSchemaIdentifiers = Set(candidates.map(\.id))
                        self.enabledModelKeys = allModelKeysForEnabledSchemas()
                    }
                    Button("None") {
                        enabledSchemaIdentifiers.removeAll()
                        enabledModelKeys.removeAll()
                    }
                }
            }
            let modelEntries = enabledModelEntries()
            Section {
                ForEach(modelEntries, id: \.key) { entry in
                    Toggle(
                        entry.displayName,
                        isOn: Binding(
                            get: { enabledModelKeys.contains(entry.key) },
                            set: { isEnabled in
                                if isEnabled {
                                    enabledModelKeys.insert(entry.key)
                                } else {
                                    enabledModelKeys.remove(entry.key)
                                }
                            }
                        )
                    )
                }
                .disabled(modelEntries.isEmpty)
            } header: {
                HStack {
                    Text("Models")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("All") {
                        self.enabledModelKeys = Set(modelEntries.map(\.key))
                    }
                    Button("None") {
                        self.enabledModelKeys.removeAll()
                    }
                }
                .disabled(modelEntries.isEmpty)
            }
            Section("Result") {
                let schema = makeSchema()
                VStack(alignment: .leading, spacing: 8) {
                    Text(schema == nil ? "No Schema Selected" : "Schema Ready")
                    Text("Schemas: \(enabledSchemaIdentifiers.count)")
                    Text("Models: \(schemaModelCount(schema))")
                }
                Button("Apply") {
                    apply(schema: schema)
                }
                .disabled(makeSchema() == nil)
            }
        }
        .onAppear {
            if enabledSchemaIdentifiers.isEmpty {
                self.enabledSchemaIdentifiers = Set(candidates.map(\.id))
                self.enabledModelKeys = allModelKeysForEnabledSchemas()
            }
        }
    }
    
    private func apply(schema: Schema?) {
        let schema = schema ?? .init()
        let configuration = Configuration(
            id: UUID().uuidString,
            types: schema.types
        ) { configuration in
            Database(
                schema: schema,
                configurations: [
                    DatabaseConfiguration(
                        transient: (),
                        types: schema.types,
                        schema: schema,
                        allowsSave: true,
                        options: [],
                        attachment: configuration.observer
                    )
                ]
            )
        }
        configurator.library = .init(configuration: configuration)
    }
    
    private func makeSchema() -> Schema? {
        let enabledCandidates = self.candidates.filter {
            enabledSchemaIdentifiers.contains($0.id)
        }
        var seen = Set<ObjectIdentifier>()
        var resolvedModels: [any PersistentModel.Type] = []
        for candidate in enabledCandidates {
            for modelType in candidate.modelTypes {
                let key = Schema.entityName(for: modelType)
                guard enabledModelKeys.contains(key) else {
                    continue
                }
                let identifier = ObjectIdentifier(modelType)
                if seen.insert(identifier).inserted {
                    resolvedModels.append(modelType)
                }
            }
        }
        guard !resolvedModels.isEmpty else {
            return nil
        }
        return Schema(resolvedModels, version: version)
    }
    
    private func schemaModelCount(_ schema: Schema?) -> Int {
        guard let schema else { return 0 }
        return schema.entities.count
    }
    
    private func enabledModelEntries() -> [(
        key: String,
        displayName: String,
        type: any PersistentModel.Type
    )] {
        let enabledCandidates = self.candidates.filter {
            enabledSchemaIdentifiers.contains($0.id)
        }
        var bucket: [String: any PersistentModel.Type] = [:]
        for candidate in enabledCandidates {
            for modelType in candidate.modelTypes {
                bucket[Schema.entityName(for: modelType)] = modelType
            }
        }
        return bucket
            .map { (key: $0, displayName: displayName(for: $0), type: $1) }
            .sorted { $0.displayName < $1.displayName }
    }
    
    private func allModelKeysForEnabledSchemas() -> Set<String> {
        Set(enabledModelEntries().map(\.key))
    }
    
    private func displayName(for modelKey: String) -> String {
        String(modelKey.split(separator: ".").last ?? Substring(modelKey))
    }
}
