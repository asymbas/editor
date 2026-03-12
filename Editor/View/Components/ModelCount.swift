//
//  ModelCount.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import Logging
import SwiftData
import SwiftUI

struct ModelCount<Model>: View where Model: PersistentModel {
    @Environment(Database.self) private var database
    @Environment(Observer.self) private var observer
    @State private var entity: Schema.Entity?
    @State private var count: Int?
    @State private var color: Color?
    
    var body: some View {
        LabeledContent(Schema.entityName(for: Model.self)) {
            Text("\(count ?? 0)")
                .foregroundStyle(color ?? .secondary)
                .contentTransition(.numericText(countsDown: false))
        }
        .task(id: observer.lastUpdated) {
            if entity == nil {
                self.entity = Schema([Model.self]).entity(for: Model.self)
            }
            guard count == nil || observer.changeTypes.contains(entity!) else {
                return
            }
            if let count = try? await database.fetchCount(FetchDescriptor<Model>()) {
                withAnimation { self.count = count }
            }
        }
    }
}
