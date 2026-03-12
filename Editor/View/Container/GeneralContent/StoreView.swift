//
//  StoreView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import SwiftData
import SwiftUI

#Preview(traits: .defaultData) {
    StoreView().preferredColorScheme(nil)
}

struct StoreView: View {
    @Environment(Database.self) private var database
    
    var body: some View {
        List(Array(database.stores.values), id: \.identifier) { store in
            let configuration = store.configuration
            Section {
                LabeledContent("Name") {
                    Text(configuration.name)
                }
                LabeledContent("Store URL") {
                    Text("\(configuration.url, default: "nil")")
                        .font(.caption.weight(.medium).monospaced())
                        .foregroundStyle(.link)
                }
                LabeledContent("External Storage URL") {
                    Text("\(configuration.externalStorageURL)")
                        .font(.caption.weight(.medium).monospaced())
                        .foregroundStyle(.link)
                }
                GroupBox(String(describing: type(of: store))) {
                    LabeledContent("DataStore") {
                        Text(String(describing: type(of: store)))
                    }
                    LabeledContent("DataStoreConfiguration") {
                        Text(String(describing: (type(of: store.configuration))))
                    }
                    let handleType = String(describing: type(of: store).Handle.self)
                    LabeledContent("Handle") {
                        Text(handleType)
                    }
                    GroupBox {
                        Text("DatabaseConnection<\(handleType)>")
                        Text(String(describing: type(of: store.queue)))
                    }.monospaced()
                }
                .font(.caption)
            } header: {
                HStack {
                    Text("Identifier: \(store.identifier)")
                        .font(.caption.weight(.medium))
                }
            }
        }
    }
}
