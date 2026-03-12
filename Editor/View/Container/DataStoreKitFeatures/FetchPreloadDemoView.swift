//
//  FetchPreloadDemoView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import DataStoreSupport
import SwiftData
import SwiftUI

#Preview(traits: .defaultData) {
    FetchPreloadDemoView()
}

struct FetchPreloadDemoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.schema) private var schema
    @State private var isLoading: Bool = false
    
    var body: some View {
        ScrollView {
            VStack {
                if isLoading {
                    ForEach(schema.entities, id: \.name) { entity in
                        if let type = entity.type {
                            model(type)
                        }
                    }
                } else {
                    ProgressView()
                    ContentUnavailableView("Using `@Fetch`...", systemImage: "star")
                        .task {
                            try? await Task.sleep(for: .seconds(2))
                            self.isLoading = true
                        }
                }
            }
            .safeAreaPadding()
        }
    }
    
    private func model<T: PersistentModel>(_ type: T.Type) -> AnyView {
        AnyView(ModelFetch<T>(type: type))
    }
    
    struct ModelFetch<T: PersistentModel>: View {
        @Fetch private var models: [T]
        
        init(type: T.Type) {
            _models = .init(FetchDescriptor<T>())
        }
        
        var body: some View {
            GroupBox {
                ForEach(models) { model in
                    ModelView(model: model)
                }
            } label: {
                Label {
                    Text(Schema.entityName(for: T.self))
                } icon: {
                    Image(systemName: (T.self as? any SystemImageNameProviding.Type)?.systemImage ?? "circle")
                }
            }
        }
        
        struct ModelView: View {
            @State private var snapshot: DatabaseSnapshot?
            var model: T
            
            var body: some View {
                VStack {
                    if let snapshot = self.snapshot {
                        DatabaseRecordView(snapshot: snapshot)
                    } else {
                        ProgressView()
                        Text(String(describing: model.persistentModelID))
                            .font(.caption.monospaced())
                            .task { self.snapshot = DatabaseSnapshot(model) }
                    }
                }
            }
        }
    }
}
