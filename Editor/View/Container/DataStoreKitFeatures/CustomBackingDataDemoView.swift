//
//  CustomBackingDataDemoView.swift
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

struct CustomBackingDataDemoView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Button("Run") {
            if let entity = try? modelContext.fetch(all: Entity.self).first {
                let _ = DatabaseSnapshot(entity)
            }
        }
    }
}
