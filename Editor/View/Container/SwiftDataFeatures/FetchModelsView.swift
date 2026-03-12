//
//  FetchModelsView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import SwiftData
import SwiftUI

#if canImport(Shared)
import Shared
#endif

#Preview(traits: .defaultData) {
    NavigationStack {
        FetchModelsView()
    }
}

struct FetchModelsView: View {
    @Environment(Library.self) private var library
    @Environment(\.modelContext) private var modelContext
    @Environment(\.schema) private var schema
    @State private var isExpanded: Bool = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Section {
                    Text("`PersistentModel` instances in `Library`.")
                    DisclosureGroup("Show All", isExpanded: $isExpanded) {
                        LibraryModelView()
                    }
                } header: {
                    Text("In-Memory")
                        .font(.title)
                        .fontWeight(.bold)
                }
                Divider()
                Section {
                    ForEach(schema.entities, id: \.name) { entity in
                        FetchCardView(entity: entity)
                    }
                } header: {
                    Text("Fetch")
                        .font(.title)
                        .fontWeight(.bold)
                }
            }
            .safeAreaPadding()
        }
    }
    
    struct FetchCardView: View {
        @Environment(Library.self) private var library
        @Environment(Observer.self) private var observer
        @Environment(\.modelContext) private var modelContext
        @Environment(\.schema) private var schema
        @State private var total: Int?
        @State private var limit: Int = .random(in: 50...100)
        @State private var offset: Int = 0
        var entity: Schema.Entity
        
        var body: some View {
            if let type = self.entity.type {
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Stepper(value: $limit) {
                            HStack {
                                Text("Limit \(limit)")
                                Button("Random", systemImage: "dice") {
                                    self.limit = .random(in: 50...100)
                                }
                            }
                        }
                        .labelStyle(.iconOnly)
                        Stepper("Offset \(offset)", value: $offset)
                        HStack {
                            Button("Fetch") {
                                Task {
                                    do {
                                        let models = try modelContext.fetch(
                                            all: type,
                                            limit: limit,
                                            offset: offset
                                        )
                                        self.library.models[entity] = models
                                        Banner(.ok, "Fetch Successful") {
                                            "Found \(models.count) \(entity.name) models."
                                        }
                                    } catch {
                                        Banner(.error, "Fetch Error") {
                                            "Fetch failed: \(error)"
                                        }
                                    }
                                }
                            }
                            Button("Preloaded Fetch") {
                                Task {
                                    do {
                                        let models = try await modelContext.preloadedFetch(
                                            all: type,
                                            limit: limit,
                                            offset: offset
                                        )
                                        self.library.models[entity] = models
                                        Banner(.ok, "Fetch Successful") {
                                            "Found \(models.count) \(entity.name) models."
                                        }
                                    } catch {
                                        Banner(.error, "Fetch Error") {
                                            "Fetch failed: \(error)"
                                        }
                                    }
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } label: {
                    Label {
                        HStack {
                            Text(entity.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(
                                total == nil || total == 0
                                ? "---"
                                : "Found in DataStore: \(total!)"
                            )
                            .animation(.spring, value: total)
                            .contentTransition(.numericText(countsDown: false))
                            .font(.caption)
                            .fontWeight(.medium)
                        }
                    } icon: {
                        Image(systemName: (type as? any SystemImageNameProviding.Type)?.systemImage ?? "circle")
                            .frame(width: 30)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .task(id: observer.lastUpdated) { @DatabaseActor in
                    let modelContainer = await library.database.modelContainer
                    let modelContext = ModelContext(modelContainer)
                    do {
                        let count = try modelContext.fetchCount(all: type)
                        await MainActor.run {
                            self.total = count
                        }
                    } catch {
                        Banner(.error, "Fetch Error") {
                            "Fetch count failed: \(error)"
                        }
                    }
                }
            }
        }
    }
}
