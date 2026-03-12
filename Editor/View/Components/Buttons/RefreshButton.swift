//
//  RefreshButton.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import DataStoreSupport
import SwiftUI

struct RefreshButton: View {
    @Environment(Database.self) private var database
    @Environment(Library.self) private var library
    
    var body: some View {
        Button("Refresh", systemImage: "arrow.trianglehead.2.clockwise.rotate.90") {
            Task { @DatabaseActor in
                await database.withDataStore { store in
                    let result = fetch(store.configuration)
                    await MainActor.run {
                        self.library.tables = result
                    }
                }
            }
        }
    }
}
