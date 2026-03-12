//
//  StoreTransferDemoView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import DataStoreRuntime
import Logging
import SwiftData
import SwiftUI

#if canImport(Shared)
import Shared
#endif

struct StoreTransferDemoView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var model: (any PersistentModel)?
    @State private var snapshot: DatabaseSnapshot?
    
    var body: some View {
        VStack {
            GroupBox {
                ModelSelector(model: $model)
                Button("Create Snapshot") {
                    if let model = self.model {
                        self.snapshot = DatabaseSnapshot(model)
                    }
                }
                .disabled(model == nil)
            } label: {
                Label("From", systemImage: "circle")
            }
            GroupBox {
                Button("Transfer") {
                    if let snapshot = self.snapshot, let model = self.model {
                        let configuration = DatabaseConfiguration(
                            name: snapshot.storeIdentifier,
                            url: .temporaryDirectory.appending(path: "\(UUID().uuidString)/test.store"),
                            options: .disableSnapshotCaching
                        )
                        // FIXME: Ensure that the transfer passes all related snapshots or it will cause a constraint error.
                        let _ = try! ModelContainer(for: snapshot.type, configurations: configuration)
                        logger.debug(
                            "Stores",
                            metadata: [
                                "lhs": "\(snapshot.storeIdentifier ?? "nil")",
                                "rhs": "\(configuration.store?.identifier ?? "nil")"
                            ]
                        )
                        try? save(model)
                        func save<T: PersistentModel>(
                            _ model: T
                        ) throws {
                            let request = DatabaseSaveChangesRequest<T, DatabaseSnapshot, DatabaseEditingState>(
                                editingState: DatabaseEditingState(),
                                inserted: [snapshot],
                                updated: [],
                                deleted: []
                            )
                            if let store = configuration.store {
                                do {
                                    let result: DatabaseSaveChangesResult<T, DatabaseSnapshot> = try store.save(request)
                                    Banner(.ok, "Successful") {
                                        "Inserted into another store: \(result)"
                                    }
                                } catch {
                                    Banner(.error, "Failed") {
                                        "Unable to insert into another store: \(error)"
                                    }
                                }
                            }
                        }
                    }
                }
                .disabled(snapshot == nil)
            } label: {
                Label("To", systemImage: "target")
            }
        }
    }
    
    struct ModelSelector: View {
        @Environment(\.modelContext) private var modelContext
        @Environment(\.schema) private var schema
        @State private var section: SectionKey?
        @State private var selected: Schema.Entity?
        @Binding var model: (any PersistentModel)?
        
        enum SectionKey: Identifiable {
            case list
            case primaryKey
            
            var id: Self { self }
        }
        
        var body: some View {
            GroupBox {
                Button("Select Models") {
                    self.section = .list
                }
                Button("Search by Primary Key") {
                    self.section = .primaryKey
                }
                Button("Random") {
                    if let entity = self.selected,
                       let type = Schema.type(for: entity.name),
                       let result = try? modelContext.fetch(all: type),
                       let model = result.randomElement() {
                        self.model = model
                    }
                }
            } label: {
                Picker(selection: $selected) {
                    ForEach(schema.entities, id: \.name) { entity in
                        Text(entity.name).tag(entity)
                    }
                } label: {
                    Label("Select a Model", systemImage: "person")
                }
            }
            .sheet(item: $section) { section in
                switch section {
                case .list:
                    ListModels(entity: selected ?? .init("Unknown"), model: $model)
                case .primaryKey:
                    IDSearch(entity: selected ?? .init("Unknown"), model: $model)
                }
            }
        }
        
        struct ListModels: View {
            @Environment(\.dismiss) private var dismiss
            @Environment(\.modelContext) private var modelContext
            @State private var task: Task<Void, any Swift.Error>?
            @State private var models: [any PersistentModel] = []
            @State private var searchText: String = ""
            var entity: Schema.Entity
            @Binding var model: (any PersistentModel)?
            
            var body: some View {
                List {
                    ForEach(models, id: \.persistentModelID) { model in
                        Button {
                            self.model = model
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(entity.name)
                                    .font(.caption2)
                                Text(model.persistentModelID.primaryKey())
                                    .font(.caption.bold())
                            }
                        }
                    }
                }
                .task {
                    do {
                        guard let type = Schema.type(for: entity.name) else {
                            return
                        }
                        let result = try modelContext.fetch(all: type)
                        self.models = result
                    } catch {
                        Banner(.error, "Fetch Error") {
                            "Unable to fetch models: \(error)"
                        }
                    }
                }
            }
        }
        
        struct IDSearch: View {
            @Environment(\.modelContext) private var modelContext
            @State private var task: Task<Void, any Swift.Error>?
            @State private var searchText: String = ""
            var entity: Schema.Entity
            @Binding var model: (any PersistentModel)?
            
            var body: some View {
                List {
                    TextField(
                        "Primary Key",
                        text: $searchText,
                        prompt: Text("Search by Primary Key...")
                    )
                    .onChange(of: searchText, initial: true) { oldValue, newValue in
                        guard !newValue.isEmpty else { return }
                        task?.cancel()
                        self.task = Task {}
                    }
                    Section {
                        EmptyView()
                    }
                }
            }
        }
    }

}
