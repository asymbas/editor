//
//  ModelPreview.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreRuntime
import SwiftData
import SwiftUI

#if canImport(Shared)
import Shared
#endif

#Preview(traits: .defaultData) {
    @Previewable @State var type: (any PersistentModel.Type)? = nil
    @Previewable @State var model: (any PersistentModel)? = nil
    ModelPreview(type: $type, model: $model)
        .safeAreaPadding()
}

struct ModelPreview: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.schema) private var schema
    @State private var models: [any PersistentModel] = []
    @Binding var type: (any PersistentModel.Type)?
    @Binding var model: (any PersistentModel)?
    
    var body: some View {
        GroupBox {
            VStack {
                ScrollView {
                    Group {
                        LabeledContent("Type") {
                            Text("\(typeName).self")
                                .font(.callout.bold().monospaced())
                                .foregroundStyle(.tint)
                        }
                        LabeledContent("Entity") {
                            Text(entityName)
                                .font(.callout.bold().monospaced())
                                .foregroundStyle(.tint)
                        }
                        LabeledContent("Primary Key") {
                            Group {
                                if let model = self.model {
                                    ScrollView(.horizontal) {
                                        Text(model.persistentModelID.primaryKey())
                                            .bold()
                                            .monospaced()
                                            .foregroundStyle(.tint)
                                    }
                                    .defaultScrollAnchor(.trailing, for: .initialOffset)
                                    .scrollIndicators(.hidden)
                                } else {
                                    Text("No Model Selected")
                                        .foregroundStyle(.placeholder)
                                }
                            }
                            .font(.callout)
                        }
                    }
                    .lineLimit(1)
                    .truncationMode(.head)
                    ResultView(selection: $model, models: models)
                }
                .scrollClipDisabled()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } label: {
            HStack {
                HStack(spacing: 4) {
                    Text(model == nil ? "Select a PersistentModel" : "PersistentModel")
                        .lineLimit(1)
                    if !models.isEmpty {
                        Text("(fetched \(models.count))")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button("Change Type", systemImage: "arrow.clockwise") {
                    execute
                }
                .labelStyle(.iconOnly)
                Button("Fetch") {
                    do {
                        if let type = self.type {
                            let models = try modelContext.fetch(all: type)
                            self.models = models
                            if let model = models.randomElement() {
                                self.model = model
                            }
                        }
                    } catch {
                        Banner(.error, "Fetch Error") {
                            "Unable to fetch \(typeName).self: \(error)"
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .clipped()
        .task(id: model?.persistentModelID) {
            if model == nil { execute }
        }
    }
    
    private var typeName: String {
        if let type = self.type {
            return String(describing: type)
        } else {
            return "nil"
        }
    }
    
    private var entityName: String {
        if let type = self.type {
            return Schema.entityName(for: type)
        } else {
            return "nil"
        }
    }
    
    private var execute: Void {
        if let type = self.schema.types.randomElement() {
            self.type = type
            self.model = nil
            self.models.removeAll(keepingCapacity: true)
        }
    }
    
    struct ResultView: View {
        @Binding var selection: (any PersistentModel)?
        var models: [any PersistentModel]
        
        var body: some View {
            DisclosureGroup("Result") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fetch and select a model.")
                    ForEach(models, id: \.persistentModelID) { model in
                        SelectButton(selection: $selection, model: model)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        
        struct SelectButton: View {
            @State private var isSelected: Bool = false
            @Binding var selection: (any PersistentModel)?
            var model: any PersistentModel
            
            var body: some View {
                Button {
                    withAnimation {
                        self.selection = model
                    }
                } label: {
                    Text(model.persistentModelID.primaryKey())
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(in: .rect(cornerRadius: 8))
                        .backgroundStyle(
                            isSelected
                            ? AnyShapeStyle(.placeholder)
                            : AnyShapeStyle(.tint)
                        )
                        .foregroundStyle(
                            isSelected
                            ? AnyShapeStyle(.placeholder)
                            : AnyShapeStyle(.white)
                        )
                }
                .disabled(isSelected)
                .task(id: selection?.persistentModelID) {
                    self.isSelected = selection?.persistentModelID == model.persistentModelID
                }
            }
        }
    }
}
