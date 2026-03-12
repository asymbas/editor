//
//  CodableDemoView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import DataStoreRuntime
import DataStoreSupport
import SwiftData
import SwiftUI

#if canImport(Shared)
import Shared
#endif

#Preview(traits: .defaultData) {
    NavigationStack {
        CodableDemoView()
            .navigationTitle("Test")
            .safeAreaPadding()
    }
    .preferredColorScheme(nil)
}

struct CodableDemoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.schema) private var schema
    @State private var fetchCount: Int?
    @State private var type: (any PersistentModel.Type)?
    @State private var model: (any PersistentModel)?
    @State private var snapshot: DatabaseSnapshot?
    @State private var data: Data?
    @State private var showPreviewSheet: Bool = false
    private var url: URL? = .init(string: "https://")
    
    var body: some View {
        VStack(spacing: 20) {
            ModelPreview(type: $type, model: $model)
                .frame(height: 150)
            VStack(alignment: .leading, spacing: 10) {
                Section {
                    ScrollView(.horizontal) {
                        HStack {
                            CardView(title: "Snapshot") {
                                if let model = self.model {
                                    withAnimation(.spring) {
                                        self.snapshot = DatabaseSnapshot(model)
                                    }
                                }
                            } content: {
                                if let snapshot = self.snapshot {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(snapshot.entityName)
                                            .bold()
                                            .foregroundStyle(.secondary)
                                        Text("\(snapshot.primaryKey)")
                                            .font(.caption2.weight(.medium).monospaced())
                                            .foregroundStyle(.tint)
                                            .lineLimit(1)
                                        LabeledContent("Properties") {
                                            Text("\(snapshot.properties.count)")
                                                .monospacedDigit()
                                                .foregroundStyle(.tint)
                                        }
                                    }
                                    .font(.caption)
                                    Divider()
                                }
                                Text(
                                    """
                                    Creates a snapshot of the `\(snapshot?.entityName ?? "nil")` model using `DatabaseSnapshot(_:)`.
                                    """
                                )
                            }
                            .disabled(model == nil)
                            .tint(snapshot == nil ? .accentColor : .green)
                            CardView(title: "Encode") {
                                if let snapshot = self.snapshot {
                                    Task { @DatabaseActor in
                                        // Test switching actors with `DatabaseSnapshot`.
                                        DatabaseActor.assertIsolated()
                                        do {
                                            let data = try JSONEncoder().encode(snapshot)
                                            await MainActor.run {
                                                withAnimation(.spring) {
                                                    self.data = data
                                                    self.snapshot = nil
                                                }
                                            }
                                        } catch {
                                            Banner.error("Encoding Error") {
                                                "Unable to encode the snapshot: \(error)"
                                            }
                                        }
                                    }
                                }
                            } content: {
                                if let data = self.data {
                                    VStack(alignment: .center, spacing: 4) {
                                        Button("Preview Encoded Data", systemImage: "eye.fill") {
                                            self.showPreviewSheet = true
                                        }
                                        .buttonStyle(.bordered)
                                        Text(data.hashValue.description)
                                            .monospaced()
                                    }
                                    Divider()
                                }
                                Text(
                                    """
                                    Encodes the `DatabaseSnapshot` instance and tests switching between actors with it. This type conforms to `Codable` and `Sendable`.
                                    \nSends the encoded JSON data to a test server:
                                    \(url == nil ? "nil" : String(describing: url!))
                                    """
                                )
                            }
                            .disabled(snapshot == nil && data == nil)
                            .tint(data == nil ? .accentColor : .green)
                            CardView(title: "Decode") {
                                if let data = self.data {
                                    Task { @DatabaseActor in
                                        // Test switching actors with `DatabaseSnapshot`.
                                        DatabaseActor.assertIsolated()
                                        do {
                                            let snapshot = try JSONDecoder().decode(
                                                DatabaseSnapshot.self,
                                                from: data
                                            )
                                            await MainActor.run {
                                                withAnimation(.spring) {
                                                    self.snapshot = snapshot
                                                    self.data = nil
                                                }
                                            }
                                        } catch {
                                            Banner.error("Decoding Error") {
                                                "Unable to decode the data: \(error)"
                                            }
                                        }
                                    }
                                }
                            } content: {
                                Text(
                                    """
                                    Requests the sent item back from the test server.
                                    \nDecodes the data back to a `DatabaseSnapshot` instance.
                                    """
                                )
                            }
                            .disabled(data == nil)
                            .tint(snapshot == nil && data != nil ? .accentColor : .green)
                        }
                        .frame(height: 250)
                    }
                    .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                    .scrollIndicators(.hidden)
                } header: {
                    Text("Demo").font(.title2.bold())
                }
            }
            Spacer()
        }
        .toolbarTitleDisplayMode(.large)
        .onAppear {
            if let type = self.schema.types.randomElement() {
                self.type = type
            }
        }
        .sheet(isPresented: $showPreviewSheet) {
            List {
                Text(preview)
                    .font(.system(.caption, design: .monospaced))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var entityName: String {
        if let type = self.type {
            return Schema.entityName(for: type)
        } else {
            return "nil"
        }
    }
    
    private var preview: String {
        if let data = self.data {
            return (try? JSONSerialization.data(
                withJSONObject: (try? JSONSerialization.jsonObject(with: data)) ?? [:],
                options: [.prettyPrinted, .sortedKeys]
            )).flatMap { String(data: $0, encoding: .utf8) }
            ?? (String(data: data, encoding: .utf8) ?? "<unreadable>")
        } else {
            return "nil"
        }
    }
    
    struct CardView<Content>: View where Content: View {
        @Environment(\.isEnabled) private var isEnabled
        var title: String
        var action: @MainActor () -> Void
        @ViewBuilder var content: Content
        
        var body: some View {
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            content
                        }
                        .font(.caption)
                        .foregroundStyle(
                            isEnabled
                            ? AnyShapeStyle(.primary)
                            : AnyShapeStyle(.placeholder)
                        )
                    }
                    .scrollClipDisabled()
                    .frame(maxHeight: .infinity)
                    Divider()
                    Button("Run") {
                        action()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } label: {
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(
                        isEnabled
                        ? AnyShapeStyle(.primary)
                        : AnyShapeStyle(.placeholder)
                    )
            }
            .aspectRatio(9 / 10, contentMode: .fit)
        }
    }
}
