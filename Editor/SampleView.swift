//
//  SampleView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct SampleView: View {
    @State private var isPresenting: Bool = false
    
    var body: some View {
        ContentUnavailableView {
            Label("DataStoreKit", systemImage: "cylinder")
                .padding(25)
        } description: {
            Text("Select a configuration to open a database with DataStoreKit and SwiftData.")
        } actions: {
            VStack {
                ScrollView {
                    CardView {
                        Text("The default configuration that uses \(DefaultSchema.models.count) model types in the schema.")
                    } label: {
                        Label("Default", systemImage: "star.fill")
                    } button: {
                        SchemaButton("Open Default Schema", for: .default)
                    }
                    CardView {
                        Text("Test migrations between SwiftData and SQLite.")
                    } label: {
                        Label("Migration", systemImage: "arrow.trianglehead.branch")
                    } button: {
                        SchemaButton("Open Migration Schema", for: .migration)
                    }
                    CardView {
                        Text("Select model types from other `Schema` configurations to use in the database.")
                    } label: {
                        Label("Custom", systemImage: "pointer.arrow.rays")
                    } button: {
                        Button("Select") {
                            self.isPresenting = true
                        }
                    }
                    .sheet(isPresented: $isPresenting) {
                        SchemaConfigurationView()
                            .interactiveDismissDisabled()
                    }
                }
                .scrollClipDisabled()
                .defaultScrollAnchor(.top)
            }
            .frame(maxWidth: 400)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 8))
    }
    
    struct CardView<Content: View, Label: View, Button: View>: View {
        @ViewBuilder var content: Content
        @ViewBuilder var label: Label
        @ViewBuilder var button: Button
        
        var body: some View {
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    content
                        .font(.callout)
                        .fontWeight(.light)
                        .foregroundStyle(.secondary)
                    button
                        .fontWeight(.medium)
                }
            } label: {
                label
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.vertical, 4)
            }
        }
    }
    
    struct SchemaConfigurationView: View {
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            NavigationStack {
                SchemaMultiSelectorView(
                    candidates: [
                        .versioned(DefaultSchema.self, title: "Default"),
                        .versioned(SampleSchema.self, title: "Sample"),
                        .versioned(TypeSchema.self, title: "Types"),
                        .versioned(FeatureSchema.self, title: "Features"),
//                        .versioned(InheritanceSchema.self, title: "Inheritance"),
                        .versioned(RelationshipSchema.self, title: "Relationship"),
                        .versioned(ConstraintSchema.self, title: "Constraints"),
                        .versioned(MigrationSchemaV1.self, title: "Migration V1"),
                        .versioned(MigrationSchemaV2.self, title: "Migration V2")
                    ]
                )
                .navigationTitle("Schema Configuration")
                .toolbar {
                    Button("Close", systemImage: "xmark", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}
