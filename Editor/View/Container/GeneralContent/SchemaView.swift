//
//  SchemaView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreSQL
import SQLiteHandle
import SwiftData
import SwiftUI

struct SchemaView: View {
    @Environment(\.schema) private var schema
    
    var body: some View {
        List {
            Button("Print") {
                print(schema)
            }
            Text(String(describing: schema))
                .font(.caption.weight(.medium).monospaced())
        }
        .navigationTitle("Schema")
    }
}
