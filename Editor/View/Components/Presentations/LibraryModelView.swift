//
//  LibraryModelView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import SwiftUI

#if canImport(Shared)
import Shared
#endif

struct LibraryModelView: View {
    @Environment(Library.self) private var library
    @Environment(\.modelContext) private var modelContext
    @Environment(\.schema) private var schema
    @State private var isConfirmingRemoveAll: Bool = false
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 25) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(totalModelCount)")
                        .font(.headline)
                    Text(totalModelCount == 1 ? "model" : "models")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(role: .destructive) {
                        self.isConfirmingRemoveAll = true
                    } label: {
                        Label("Remove All", systemImage: "trash")
                            .labelStyle(.iconOnly)
                    }
                    .disabled(groups.isEmpty)
                    .confirmationDialog(
                        Text("Remove"),
                        isPresented: $isConfirmingRemoveAll,
                        titleVisibility: .visible
                    ) {
                        Button("Delete From ModelContext", role: .destructive) {
                            deleteAll()
                        }
                        Button("Remove From Library", role: nil) {
                            removeAll()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Deleting will result in the loss of all models in the library.")
                    }
                }
                if !groups.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(groups, id: \.id) { group in
                            CardView(group: group)
                        }
                    }
                    .transition(.scale)
                } else {
                    Text("No models in `library.models`.")
                        .foregroundStyle(.secondary)
                        .transition(.blurReplace)
                }
            }
            .animation(.spring, value: groups)
        } label: {
            HStack {
                Label("Library Models", systemImage: "tray.full")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Menu("More", systemImage: "ellipsis") {
                    Text("")
                }
                .labelStyle(.iconOnly)
            }
            .padding(.vertical, 5)
        }
    }
    
    private var totalModelCount: Int {
        library.models.values.reduce(0) { $0 + $1.count }
    }
    
    private var groups: [Group] {
        library.models
            .map { entity, models in
                Group(
                    id: entity.name,
                    entity: entity,
                    systemImage: (entity.type as? SystemImageNameProviding.Type)?.systemImage ?? "circle",
                    models: models
                )
            }
            .sorted { lhs, rhs in
                lhs.entity.name.localizedStandardCompare(rhs.entity.name) == .orderedAscending
            }
    }
    
    private func deleteAll() {
        for models in library.models.values {
            for model in models {
                modelContext.delete(model)
            }
        }
        do {
            try modelContext.save()
            removeAll()
        } catch {
            Banner(.error, "Save Error") {
                "Failed to save changes: \(error)"
            }
        }
    }
    
    private func removeAll() {
        Task { withAnimation { library.models.removeAll() } }
    }
    
    struct Group: Equatable {
        let id: String
        let entity: Schema.Entity
        let systemImage: String
        let models: [any PersistentModel]
        
        nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id && lhs.models.count == rhs.models.count
        }
    }
    
    struct CardView: View {
        @Environment(Library.self) private var library
        @Environment(\.modelContext) private var modelContext
        @State private var isConfirmingRemoveEntity: Bool = false
        var group: Group
        
        var body: some View {
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(group.models.count)")
                            .font(.headline)
                        Text(group.models.count == 1 ? "record" : "records")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(role: .destructive) {
                            self.isConfirmingRemoveEntity = true
                        } label: {
                            Label("Remove", systemImage: "trash")
                                .labelStyle(.iconOnly)
                        }
                        .confirmationDialog(
                            Text("Remove \(group.entity.name)?"),
                            isPresented: $isConfirmingRemoveEntity,
                            titleVisibility: .visible
                        ) {
                            Button("Delete From ModelContext", role: .destructive) {
                                deleteAll()
                            }
                            Button("Remove From Library", role: nil) {
                                removeAll()
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("Deleting will result in the loss of all models in the library.")
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(sortedModels, id: \.persistentModelID) { model in
                            ModelRow(model: model)
                        }
                    }
                }
            } label: {
                Label {
                    Text(group.entity.name)
                } icon: {
                    Image(systemName: group.systemImage)
                        .frame(width: 30)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        
        private var sortedModels: [any PersistentModel] {
            group.models.sorted { $0.persistentModelID < $1.persistentModelID }
        }
        
        private func deleteAll() {
            for model in group.models {
                modelContext.delete(model)
            }
            do {
                try modelContext.save()
                removeAll()
            } catch {
                Banner(.error, "Save Error") {
                    "Failed to save changes: \(error)"
                }
            }
        }
        
        private func removeAll() {
            Task { withAnimation { library.models[group.entity] = nil } }
        }
        
        struct ModelRow: View {
            @State private var isExpanded: Bool = false
            let model: any PersistentModel
            
            var body: some View {
                DisclosureGroup(isExpanded: $isExpanded) {
                    Text(String(describing: model))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    HStack {
                        Text(String(describing: model.persistentModelID))
                            .font(.caption)
                            .monospaced()
                            .lineLimit(1)
                        Spacer()
                        Text(String(describing: type(of: model)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}
