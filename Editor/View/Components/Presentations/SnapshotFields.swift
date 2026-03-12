//
//  SnapshotFields.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import DataStoreRuntime
import SwiftData
import SwiftUI

// present sql

#Preview("Select", traits: .defaultData) {
    @Previewable @State var type: (any PersistentModel.Type)?
    @Previewable @State var model: (any PersistentModel)?
    List {
        ModelPreview(type: $type, model: $model)
            .frame(maxWidth: 400, maxHeight: 200)
            .listRowBackground(Color.clear)
        if let model {
            DatabaseRecordView(snapshot: .init(model))
        }
    }
}

#Preview("Query", traits: .defaultData) {
    @Previewable @Query var users: [Entity] = []
    if let user = users.first {
        List {
            DatabaseRecordView(snapshot: .init(user))
        }
    }
}

struct DatabaseRecordLink: View {
    var snapshot: DatabaseSnapshot
    
    var body: some View {
        NavigationLink {
            List { DatabaseRecordView(snapshot: snapshot) }
        } label: {
            Label(
                "\(snapshot.entityName) Snapshot",
                systemImage: "camera.viewfinder"
            )
        }
    }
}

struct DatabaseRecordView: View {
    @Binding var snapshot: DatabaseSnapshot
    
    init(snapshot: DatabaseSnapshot) {
        _snapshot = .constant(snapshot)
    }
    
    init(snapshot: Binding<DatabaseSnapshot>) {
        _snapshot = snapshot
    }
    
    var body: some View {
        Section {
            ForEach(snapshot.properties.indices, id: \.self) { index in
                let property = snapshot.properties[index]
                PropertyRow(
                    property: property,
                    value: Binding(
                        get: { snapshot.values[index] },
                        set: { snapshot.values[index] = $0 }
                    )
                ) {
                    VStack {
                        let value = self.snapshot.values[index]
                        switch property.metadata {
                        case is Schema.Relationship:
                            switch value {
                            case let identifiers as [PersistentIdentifier]:
                                let value = identifiers
                                    .map { $0.primaryKey() }
                                    .joined(separator: ",\n")
                                if !value.isEmpty {
                                    Text(value)
                                } else {
                                    Text("[]")
                                }
                            case let identifier as PersistentIdentifier:
                                Text(identifier.primaryKey())
                            case let value:
                                Text(String(describing: value))
                            }
                        case is Schema.Attribute:
                            Text(String(describing: value))
                        default:
                            EmptyView()
                        }
                    }
                    .font(.caption.weight(.medium))
                    .monospaced(property.valueType is String.Type == false)
                    .foregroundStyle(.tint)
                }
            }
        } header: {
            HStack {
                Text(snapshot.entityName)
                Spacer(minLength: 0)
                Text(snapshot.primaryKey)
                    .font(.caption.monospaced())
            }
            .lineLimit(1)
        } footer: {
            Text("\(snapshot.properties.count) properties, \(snapshot.properties.count(where: \.isAttribute)) attributes, \(snapshot.properties.count(where: \.isRelationship)) relationships")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
    
    struct PropertyRow<Label: View>: View {
        @State private var isExpanded: Bool = false
        var property: PropertyMetadata
        @Binding var value: any DataStoreSnapshotValue
        @ViewBuilder var label: Label
        
        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                RecordField(property: property, value: $value)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(property.name)
                            .monospaced()
                        Spacer(minLength: 0)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    label
                }
            }
        }
    }
}
