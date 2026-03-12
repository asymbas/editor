//
//  InformationSectionView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftData
import SwiftUI

#Preview(traits: .defaultData) {
    InformationSectionView()
        .preferredColorScheme(.dark)
}

struct InformationSectionView: View {
    @Environment(Database.self) private var database
    @State private var isShowingLicense: Bool = false
    
    var body: some View {
        List {
            Section("General") {
                Text("Editor Application")
            }
            Section {
                VStack(alignment: .leading) {
                    Text("Asymbas Inc.")
                        .font(.headline)
                    Text("Anferne Pineda")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
