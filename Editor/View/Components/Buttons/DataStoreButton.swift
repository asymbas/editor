//
//  DataStoreButton.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import DataStoreSupport
import SwiftUI

struct DataStoreButton: View {
    @DatabaseActor @Environment(Database.self) private var database
    private let action: @DatabaseActor (DatabaseStore) -> Void
    private var title: Text
    private var icon: Image?
    
    init(
        _ titleKey: LocalizedStringKey,
        systemImage: String? = nil,
        action: @escaping @DatabaseActor (DatabaseStore) -> Void
    ) {
        self.title = Text(titleKey)
        self.icon = systemImage.map(Image.init(systemName:))
        self.action = action
    }
    
    var body: some View {
        Button {
            Task { @DatabaseActor in
                await database.withDataStore { store in
                    action(store)
                }
            }
        } label: {
            Label {
                title
            } icon: {
                if let icon = self.icon {
                    icon
                }
            }
        }
    }
}
