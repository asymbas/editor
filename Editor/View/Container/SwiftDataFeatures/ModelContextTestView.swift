//
//  ModelContextTestView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreRuntime
import DataStoreSupport
import SwiftData
import SwiftUI

#if canImport(Shared)
import Shared
#endif

struct ModelContextTestView: View {
    @DatabaseActor @Environment(\.modelContext) private var modelContext
    @State private var id: UUID = .init()
    
    var body: some View {
        List {
            ModelContextArrayView()
                .id(id)
            Section("Save") {
                Text("`try modelContext.save()`")
                TestButton("Run", systemImage: "square.and.arrow.down") {
                    try modelContext.save()
                    await MainActor.run { self.id = .init() }
                } onEvaluation: { _ in
                    true
                }
            }
            Section("Insert") {
                Text("`modelContext.insert(_:)`")
                TestButton("Run", systemImage: "plus") {
                    let entity = Entity()
                    modelContext.insert(entity)
                    await MainActor.run { self.id = .init() }
                    try modelContext.save()
                    return entity.persistentModelID
                } onEvaluation: { persistentIdentifier in
                    try modelContext.fetch(FetchDescriptor(predicate: #Predicate<Entity> {
                        $0.persistentModelID == persistentIdentifier
                    })).first != nil
                }
            }
            Section("Delete") {
                Text("`modelContext.delete(_:)`")
                TestButton("Run", systemImage: "trash") { () -> PersistentIdentifier? in
                    if let model = try modelContext.fetch(all: Entity.self).first {
                        modelContext.delete(model)
                        await MainActor.run { self.id = .init() }
                        return model.persistentModelID
                    } else {
                        Banner.warning("Test Failed") {
                            "No models found to delete."
                        }
                        return nil
                    }
                } onEvaluation: { persistentIdentifier in
                    switch persistentIdentifier {
                    case let persistentIdentifier?:
                        try modelContext.fetch(FetchDescriptor(predicate: #Predicate<Entity> {
                            $0.persistentModelID == persistentIdentifier
                        })).first == nil
                    case nil:
                        false
                    }
                }
            }
            Section("Fetch") {
                Group {
                    Text("`modelContext.model(for:)`")
                    TestButton("Run", systemImage: "circle") {
                        let modelContext = self.modelContext
                        let modelContainer = modelContext.container
                        return try await MainActor.run {
                            let modelContext = ModelContext(modelContainer)
                            let model = Entity()
                            modelContext.insert(model)
                            self.id = .init()
                            try modelContext.save()
                            return model.persistentModelID
                        }
                    } onEvaluation: { persistentIdentifier in
                        if let type = Schema.type(for: persistentIdentifier.entityName) {
                            return cast(type)
                        } else {
                            return false
                        }
                        @DatabaseActor func cast<T: PersistentModel>(_ type: T.Type) -> Bool {
                            modelContext.model(for: persistentIdentifier) as? T != nil
                        }
                    }
                }
                Group {
                    Text("`modelContext.registeredModel(for:)`")
                    TestButton("Run", systemImage: "circle") {
                        let modelContext = self.modelContext
                        let modelContainer = modelContext.container
                        return try await MainActor.run {
                            let modelContext = ModelContext(modelContainer)
                            let model = Entity()
                            modelContext.insert(model)
                            self.id = .init()
                            try modelContext.save()
                            return model.persistentModelID
                        }
                    } onEvaluation: { persistentIdentifier in
                        if let type = Schema.type(for: persistentIdentifier.entityName) {
                            return cast(type)
                        } else {
                            return false
                        }
                        @DatabaseActor func cast<T: PersistentModel>(_ type: T.Type) -> Bool {
                            let model: T? = modelContext.registeredModel(for: persistentIdentifier)
                            return model != nil
                        }
                    }
                }
            }
        }
        .environment(\.autoRunOnAppear, false)
    }
    
    struct ModelContextArrayView: View {
        @Environment(\.modelContext) private var modelContext
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                content("Inserted Models Array", models: modelContext.insertedModelsArray)
                content("Changed Models Array", models: modelContext.changedModelsArray)
                content("Deleted Models Array", models: modelContext.deletedModelsArray)
            }
        }
        
        @ViewBuilder
        private func content(_ title: String, models: [any PersistentModel]) -> some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.weight(.semibold))
                VStack {
                    if !models.isEmpty {
                        ForEach(models, id: \.persistentModelID) { model in
                            HStack {
                                Text(model.persistentModelID.entityName)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                Text(model.persistentModelID.primaryKey())
                                    .monospaced()
                            }
                            .foregroundStyle(.tint)
                        }
                    } else {
                        Text("Empty")
                            .fontWeight(.medium)
                            .foregroundStyle(.placeholder)
                    }
                }
                .font(.caption)
            }
        }
    }
}
