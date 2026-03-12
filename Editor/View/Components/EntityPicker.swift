//
//  EntityPicker.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Collections
import DataStoreRuntime
import SwiftData
import SwiftUI

struct EntityPicker<Selection: Hashable, Content: View, Label: View>: View {
    @Environment(\.schema) private var schema
    @Binding var selection: Selection
    @ViewBuilder var content: (Schema.Entity) -> Content
    @ViewBuilder var label: Label
    
    var body: some View {
        Picker(selection: $selection) {
            ForEach(schema.entities, id: \.name) { entity in
                content(entity)
            }
        } label: {
            label
        }
    }
}

struct PropertyPicker: View {
    @Binding var selection: OrderedSet<PropertyMetadata>
    var entity: Schema.Entity
    var predicate: (PropertyMetadata) -> Bool = { _ in true }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(entity.type!.databaseSchemaMetadata, id: \.name) { property in
                    HStack {
                        let isSelected = self.selection.contains(property)
                        ScrollView(.horizontal) {
                            HStack {
                                Text(property.description)
                                    .fontWeight(.medium)
                                    .fontDesign(.monospaced)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .scrollClipDisabled()
                        Button {
                            switch isSelected {
                            case true: selection.remove(property)
                            case false: selection.insert(property, at: 0)
                            }
                        } label: {
                            Label {
                                Text(isSelected ? "Deselect" : "Select")
                                    .fontWeight(.bold)
                            } icon: {
                                Image(systemName: isSelected ? "checkmark.square" : "square")
                                    .imageScale(.large)
                            }
                        }
                    }
                    .font(.caption)
                }
            }
        }
    }
}
