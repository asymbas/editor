//
//  RecordField.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import Foundation
import SwiftData
import SwiftUI
import System

#if canImport(Shared)
import Shared
#endif

struct RecordField: View {
    let property: PropertyMetadata
    @Binding var value: any DataStoreSnapshotValue
    var isUniquenessViolation: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HeaderView(
                property: property,
                isUniquenessViolation: isUniquenessViolation
            )
            ValueField(property: property, value: $value)
            SQLPreview(value: value)
        }
        .padding(12)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isUniquenessViolation ? Color.red : Color.secondary.opacity(0.1),
                    lineWidth: isUniquenessViolation ? 1.5 : 1
                )
        }
    }
    
    struct SQLPreview: View {
        @State private var sql: String = ""
        var value: any DataStoreSnapshotValue
        
        var body: some View {
            DisclosureGroup {
                GroupBox {
                    Text(sql)
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .fontWeight(.medium)
                        .textSelection(.enabled)
                } label: {
                    HStack {
                        Text(SQLType(for: Swift.type(of: value))?.sql ?? "<unknown>")
                            .font(.callout)
                            .fontDesign(.monospaced)
                            .fontWeight(.bold)
                            .textSelection(.enabled)
                            .task { self.sql = SQLValue(any: value).sql }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button("Copy to Clipboard", systemImage: "clipboard") {
                            if copyToClipboard(sql) {
                                Banner(.ok, "Copied")
                            }
                        }
                        .buttonStyle(.bordered)
                        .labelStyle(.iconOnly)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } label: {
                Text("SQL Representation")
                    .font(.subheadline.weight(.medium))
            }
        }
    }
    
    struct HeaderView: View {
        var property: PropertyMetadata
        var isUniquenessViolation: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(property.name)
                        .font(.headline)
                        .foregroundStyle(isUniquenessViolation ? .red : .primary)
                    if property.isUnique {
                        Badge(
                            title: isUniquenessViolation ? "Not Unique" : "Unique",
                            color: isUniquenessViolation ? .red : .orange
                        )
                    }
                    if property.isOptional {
                        Badge(title: "Optional", color: .secondary)
                    }
                    Spacer()
                }
                Text("\(propertyKind) • \(typeName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        
        private var propertyKind: String {
            if property.isCompositeAttribute { return "Composite attribute" }
            if property.isToOneRelationship { return "To-One relationship" }
            if property.isManyToManyRelationship { return "Many-to-Many relationship" }
            if property.isRelationship { return "Relationship" }
            if property.isAttribute { return "Attribute" }
            return "Property"
        }
        
        private var typeName: String {
            String(reflecting: property.valueType)
        }
        
        struct Badge: View {
            var title: String
            var color: Color
            
            var body: some View {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.12), in: Capsule())
                    .foregroundStyle(color)
            }
        }
    }
    
    struct ValueField: View {
        var property: PropertyMetadata
        @Binding var value: any DataStoreSnapshotValue
        
        var body: some View {
            switch property.valueType {
            case is Bool.Type, is Bool?.Type:
                if let binding = $value.cast(to: Bool.self) {
                    BoolRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: Bool?.self) {
                    OptionalRecordValueEditor(value: binding, default: false) { binding in
                        BoolRecordValueEditor(value: binding)
                    }
                }
            case is Float.Type, is Float?.Type:
                if let binding = $value.cast(to: Float.self) {
                    LosslessStringRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: Float?.self) {
                    OptionalRecordValueEditor(value: binding, default: 0) { binding in
                        LosslessStringRecordValueEditor(value: binding)
                    }
                }
            case is Double.Type, is Double?.Type:
                if let binding = $value.cast(to: Double.self) {
                    LosslessStringRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: Double?.self) {
                    OptionalRecordValueEditor(value: binding, default: 0) { binding in
                        LosslessStringRecordValueEditor(value: binding)
                    }
                }
            case is Date.Type, is Date?.Type:
                if let binding = $value.cast(to: Date.self) {
                    DateRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: Date?.self) {
                    OptionalRecordValueEditor(value: binding, default: .now) { binding in
                        DateRecordValueEditor(value: binding)
                    }
                }
            case is Int.Type, is Int?.Type:
                if let binding = $value.cast(to: Int.self) {
                    LosslessStringRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: Int?.self) {
                    OptionalRecordValueEditor(value: binding, default: 0) { binding in
                        LosslessStringRecordValueEditor(value: binding)
                    }
                }
            case is Int8.Type, is Int8?.Type:
                if let binding = $value.cast(to: Int8.self) {
                    LosslessStringRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: Int8?.self) {
                    OptionalRecordValueEditor(value: binding, default: 0) { binding in
                        LosslessStringRecordValueEditor(value: binding)
                    }
                }
            case is Int16.Type, is Int16?.Type:
                if let binding = $value.cast(to: Int16.self) {
                    LosslessStringRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: Int16?.self) {
                    OptionalRecordValueEditor(value: binding, default: 0) { binding in
                        LosslessStringRecordValueEditor(value: binding)
                    }
                }
            case is Int32.Type, is Int32?.Type:
                if let binding = $value.cast(to: Int32.self) {
                    LosslessStringRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: Int32?.self) {
                    OptionalRecordValueEditor(value: binding, default: 0) { binding in
                        LosslessStringRecordValueEditor(value: binding)
                    }
                }
            case is Int64.Type, is Int64?.Type:
                if let binding = $value.cast(to: Int64.self) {
                    LosslessStringRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: Int64?.self) {
                    OptionalRecordValueEditor(value: binding, default: 0) { binding in
                        LosslessStringRecordValueEditor(value: binding)
                    }
                }
            case is UInt.Type, is UInt?.Type:
                if let binding = $value.cast(to: UInt.self) {
                    LosslessStringRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: UInt?.self) {
                    OptionalRecordValueEditor(value: binding, default: 0) { binding in
                        LosslessStringRecordValueEditor(value: binding)
                    }
                }
            case is UInt8.Type, is UInt8?.Type:
                if let binding = $value.cast(to: UInt8.self) {
                    LosslessStringRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: UInt8?.self) {
                    OptionalRecordValueEditor(value: binding, default: 0) { binding in
                        LosslessStringRecordValueEditor(value: binding)
                    }
                }
            case is UInt16.Type, is UInt16?.Type:
                if let binding = $value.cast(to: UInt16.self) {
                    LosslessStringRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: UInt16?.self) {
                    OptionalRecordValueEditor(value: binding, default: 0) { binding in
                        LosslessStringRecordValueEditor(value: binding)
                    }
                }
            case is UInt32.Type, is UInt32?.Type:
                if let binding = $value.cast(to: UInt32.self) {
                    LosslessStringRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: UInt32?.self) {
                    OptionalRecordValueEditor(value: binding, default: 0) { binding in
                        LosslessStringRecordValueEditor(value: binding)
                    }
                }
            case is UInt64.Type, is UInt64?.Type:
                if let binding = $value.cast(to: UInt64.self) {
                    LosslessStringRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: UInt64?.self) {
                    OptionalRecordValueEditor(value: binding, default: 0) { binding in
                        LosslessStringRecordValueEditor(value: binding)
                    }
                }
            case is String.Type, is String?.Type:
                if let binding = $value.cast(to: String.self) {
                    StringRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: String?.self) {
                    OptionalRecordValueEditor(value: binding, default: "") { binding in
                        StringRecordValueEditor(value: binding)
                    }
                }
            case is FilePath.Type, is FilePath?.Type:
                if let binding = $value.cast(to: FilePath.self) {
                    FilePathRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: FilePath?.self) {
                    OptionalRecordValueEditor(value: binding, default: .init()) { binding in
                        FilePathRecordValueEditor(value: binding)
                    }
                }
            case is URL.Type, is URL?.Type:
                if let binding = $value.cast(to: URL.self) {
                    URLRecordValueEditor(value: binding)
                } else if let binding = $value.cast(to: URL?.self) {
                    OptionalRecordValueEditor(value: binding, default: .init(filePath: "")) { binding in
                        URLRecordValueEditor(value: binding)
                    }
                }
            case is UUID.Type, is UUID?.Type:
                UnsupportedRecordValueEditor(value: value)
            case is Data.Type, is Data?.Type:
                UnsupportedRecordValueEditor(value: value)
            default:
                UnsupportedRecordValueEditor(value: value)
            }
        }
    }
    
    struct BoolRecordValueEditor: View {
        @Binding var value: Bool
        
        var body: some View {
            Toggle("Value", isOn: $value)
        }
    }
    
    struct DateRecordValueEditor: View {
        @Binding var value: Date
        
        var body: some View {
            DatePicker("Value", selection: $value)
        }
    }
    
    struct StringRecordValueEditor: View {
        @Binding var value: String
        
        var body: some View {
            TextField("Value", text: $value)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    struct LosslessStringRecordValueEditor<Value>: View
    where Value: Equatable & LosslessStringConvertible {
        @Binding var value: Value
        
        var body: some View {
            TextField(
                "Value",
                text: Binding(
                    get: { String(value) },
                    set: { newValue in
                        if let parsed = Value(newValue) {
                            self.value = parsed
                        }
                    }
                )
            )
            .textFieldStyle(.roundedBorder)
        }
    }
    
    struct FilePathRecordValueEditor: View {
        @Binding var value: FilePath
        
        var body: some View {
            TextField(
                "Path",
                text: Binding(
                    get: { String(decoding: value) },
                    set: { self.value = FilePath($0) }
                ),
                axis: .vertical
            )
            .textFieldStyle(.roundedBorder)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.system(.body, design: .monospaced))
        }
    }
    
    struct URLRecordValueEditor: View {
        @Binding var value: URL
        
        var body: some View {
            TextField(
                value.isFileURL ? "Path" : "URL",
                text: Binding(
                    get: { value.isFileURL ? value.path : value.absoluteString },
                    set: { newValue in
                        if value.isFileURL {
                            self.value = URL(fileURLWithPath: newValue)
                        } else if let url = URL(string: newValue) {
                            self.value = url
                        }
                    }
                )
            )
            .textFieldStyle(.roundedBorder)
        }
    }
    
    struct OptionalRecordValueEditor<Content, Wrapped>: View
    where Content: Sendable & View, Wrapped: DataStoreSnapshotValue {
        @Binding private var value: Wrapped?
        private let defaultValue: @Sendable () -> Wrapped
        private let content: (Binding<Wrapped>) -> Content
        
        init(
            value: Binding<Wrapped?>,
            default defaultValue: @autoclosure @escaping @Sendable () -> Wrapped,
            @ViewBuilder content: @escaping (Binding<Wrapped>) -> Content
        ) {
            self._value = value
            self.defaultValue = defaultValue
            self.content = content
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Picker("State", selection: Binding(
                    get: { value == nil },
                    set: { newValue in
                        if newValue {
                            self.value = nil
                        } else if value == nil {
                            self.value = defaultValue()
                        }
                    }
                )) {
                    Text("Value").tag(false)
                    Text("Nil").tag(true)
                }
                .pickerStyle(.segmented)
                if value != nil {
                    content($value.unwrapped(or: defaultValue()))
                }
            }
        }
    }
    
    struct UnsupportedRecordValueEditor: View {
        let value: any DataStoreSnapshotValue
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text("Unsupported Editor")
                    .font(.subheadline.weight(.medium))
                Text(String(describing: value))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private extension Binding where Value == any DataStoreSnapshotValue {
    func cast<T>(to type: T.Type) -> Binding<T>? where T: DataStoreSnapshotValue {
        guard wrappedValue is T else { return nil }
        return .init(
            get: { self.wrappedValue as! T },
            set: { self.wrappedValue = $0 }
        )
    }
}

private extension Binding where Value: DataStoreSnapshotValue {
    func unwrapped<Wrapped>(or defaultValue: @autoclosure @escaping @Sendable () -> Wrapped) -> Binding<Wrapped> where Value == Wrapped? {
        .init(
            get: { self.wrappedValue ?? defaultValue() },
            set: { self.wrappedValue = $0 }
        )
    }
}
