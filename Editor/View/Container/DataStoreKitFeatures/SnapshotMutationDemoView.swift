//
//  SnapshotMutationDemoView.swift
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

#if canImport(Shared)
import Shared
#endif

struct SnapshotMutationDemoView: View {
    @State private var type: (any PersistentModel.Type)?
    @State private var model: (any PersistentModel)?
    @State private var snapshot: DatabaseSnapshot?
    @State private var propertyName: String?
    @State private var propertyKeyPath: (any AnyKeyPath & Sendable)?
    @State private var value: (any DataStoreSnapshotValue)?
    @State private var shouldTestSupportedTypes: Bool = true
    
    private let newValueMap: [ObjectIdentifier: any DataStoreSnapshotValue] = [
        .init(Bool.self): Bool.random(),
        .init(Int.self): Int.random(in: Int.min...Int.max),
        .init(Double.self): Double.random(in: -1000.0...1000.0),
        .init(Date.self): Date(),
        .init(String.self): "test",
        .init(URL.self): URL(string: "https://example.com")!,
        .init(UUID.self): UUID(),
        .init(Data.self): Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    ]
    
    var body: some View {
        List {
            ModelPreview(type: $type, model: $model)
                .groupBoxStyle(BasicGroupBoxStyle())
            if let snapshot = self.snapshot {
                DatabaseRecordLink(snapshot: snapshot)
            }
            Section("Get Value") {
                if let keyPath = self.propertyKeyPath {
                    Button {
                        self.value = snapshot?.getValue(keyPath: keyPath)
                    } label: {
                        VStack(alignment: .leading) {
                            Text("Run `getValue(keyPath:)`")
                            Text(String(describing: keyPath))
                                .font(.caption.weight(.medium).monospaced())
                                .lineLimit(1)
                                .truncationMode(.head)
                        }
                    }
                }
                if let name = self.propertyName {
                    Button {
                        self.value = snapshot?.getValue(name: name)
                    } label: {
                        VStack(alignment: .leading) {
                            Text("Run `getValue(name:)`")
                            Text(name)
                                .font(.caption.weight(.medium).monospaced())
                                .lineLimit(1)
                                .truncationMode(.head)
                        }
                    }
                }
                LabeledContent {
                    Text(String(describing: value == nil ? "nil" : value!))
                        .font(.caption.weight(.medium).monospaced())
                        .lineLimit(1)
                        .truncationMode(.head)
                        .foregroundStyle(value == nil ? Color.secondary : .accentColor)
                } label: {
                    Text("Snapshot Value")
                        .font(.callout)
                }
                Text("Get value from snapshot")
            }
            Section("Set Value") {
                if let keyPath = self.propertyKeyPath {
                    let valueType = self.snapshot?.getProperty(keyPath: keyPath)?.valueType
                    Button {
                        if let valueType,
                           let newValue = self.newValueMap[ObjectIdentifier(valueType)] {
                            let oldValue = snapshot?.setValue(newValue, keyPath: keyPath)
                            self.value = newValue
                            Banner("Snapshot Value Set") {
                                """
                                Old: \(String(describing: oldValue))
                                New: \(String(describing: newValue))
                                """
                            }
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text("Run `setValue(keyPath:)`")
                            Text(String(describing: keyPath))
                                .font(.caption.weight(.medium).monospaced())
                                .lineLimit(1)
                                .truncationMode(.head)
                        }
                    }
                    .disabled(
                        valueType == nil
                        ? true
                        : newValueMap[ObjectIdentifier(valueType!)] == nil
                    )
                }
                if let name = self.propertyName {
                    let valueType = self.snapshot?.getProperty(name: name)?.valueType
                    Button {
                        if let valueType,
                           let newValue = self.newValueMap[ObjectIdentifier(valueType)] {
                            let oldValue = snapshot?.setValue(newValue, name: name)
                            self.value = newValue
                            Banner("Snapshot Value Set") {
                                """
                                Old: \(String(describing: oldValue))
                                New: \(String(describing: newValue))
                                """
                            }
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text("Run `setValue(name:)`")
                            Text(name)
                                .font(.caption.weight(.medium).monospaced())
                                .lineLimit(1)
                                .truncationMode(.head)
                        }
                    }
                }
                Text("Set value from snapshot")
            }
        }
        .toolbar {
            Toggle("Supported Types", isOn: $shouldTestSupportedTypes)
        }
        .task(id: model?.persistentModelID) {
            if let model = self.model {
                self.snapshot = DatabaseSnapshot(model)
                let filteredProperties = self.snapshot?.properties.filter {
                    newValueMap[ObjectIdentifier($0.valueType)] != nil
                    || shouldTestSupportedTypes == false
                }
                self.propertyName = filteredProperties?.randomElement()?.name
                self.propertyKeyPath = filteredProperties?.randomElement()?.keyPath
            } else {
                self.type = nil
                self.model = nil
                self.snapshot = nil
                self.propertyName = nil
                self.propertyKeyPath = nil
            }
        }
    }
}
