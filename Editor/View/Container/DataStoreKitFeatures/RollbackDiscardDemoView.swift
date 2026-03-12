//
//  RollbackDiscardDemoView.swift
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
    @Previewable @State var model = Entity()
    NavigationStack {
        NavigationLink("Open Editor") {
            RollbackDiscardDemoView(model: model)
        }
    }
}

struct RollbackDiscardDemoView: View {
    var model: (any PersistentModel)?
    
    var body: some View {
        EmptyView()
    }
}
