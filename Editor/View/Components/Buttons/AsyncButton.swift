//
//  AsyncButton.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct AsyncButton<Label: View>: View {
    @State private var task: Task<Void, any Error>?
    @State private var isLoading: Bool = false
    private let action: @MainActor () -> Void
    private var title: Text
    private var icon: Image?
    
    init(
        _ titleKey: LocalizedStringKey,
        systemImage: String? = nil,
        action: @escaping @MainActor () -> Void
    ) {
        self.title = Text(titleKey)
        self.icon = systemImage.map(Image.init(systemName:))
        self.action = action
    }
    
    init(
        _ titleKey: LocalizedStringKey,
        action: @escaping @MainActor () -> Void
    ) where Label == EmptyView {
        self.title = Text(titleKey)
        self.icon = nil
        self.action = action
    }
    
    var body: some View {
        Button {
            task?.cancel()
            self.isLoading = true
            self.task = Task {
                action()
                self.isLoading = false
            }
        } label: {
            if !isLoading {
                SwiftUI.Label(title: { title }, icon: { icon })
            } else {
                ProgressView()
            }
        }
        .disabled(isLoading)
    }
}
