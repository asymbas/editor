//
//  MergeDataDemoView.swift
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

struct MergeDataDemoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.schema) private var schema
    @State private var model: (any PersistentModel)?
    @State private var snapshot: DatabaseSnapshot?
    
    var body: some View {
        List {
            Button("Typed Run") {
                do {
                    if let model = try modelContext.fetch(all: User.self).first {
                        let snapshot = DatabaseSnapshot(model)
                        let template = User(name: "Test")
                        #if false
                        try snapshot.insert(into: template, modelContext: modelContext)
                        #endif
                    }
                } catch {
                    logger.error("Insert error: \(error)")
                }
            }
            Button("Run") {
                if let model = self.model {
                    let type = type(of: model)
                    make(type)
                }
            }
            .disabled(snapshot == nil)
        }
        .onAppear {
            if let entity = self.schema.entities.randomElement(),
               let type = Schema.type(for: entity.name),
               let model = try? modelContext.fetch(all: type).first {
                self.model = model
                self.snapshot = DatabaseSnapshot(model)
            }
        }
    }
    
    private func make<T>(_ type: T.Type) where T: PersistentModel {
        let template = type.init(backingData: T.createBackingData())
        do {
            #if false
            try snapshot?.insert(into: template)
            #endif
        } catch {
            logger.error("Insert error: \(error)")
        }
    }
}
