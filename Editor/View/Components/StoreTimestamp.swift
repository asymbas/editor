//
//  StoreTimestamp.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct StoreTimestamp: View {
    @Environment(Observer.self) private var observer
    @AppStorage("preview-mode") private var previewMode: Bool = false
    
    var body: some View {
        let timestamp = self.observer.lastUpdated?.formatted(
            date: .long,
            time: .complete
        ) ?? "Unknown"
        Text("Last updated: \(previewMode ? placeholder : timestamp)")
    }
    
    private var placeholder: String {
        "December 1, 2025 at 12:00:00 AM MST"
    }
}
