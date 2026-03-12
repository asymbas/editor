//
//  PreviewSnapshotModifier.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import SwiftData
import SwiftUI

#if canImport(Shared)
import Shared
#endif

extension View {
    func previewSnapshot<Selection: Hashable & Sendable>(
        for selection: Binding<Selection?>,
        makePersistentIdentifier: @escaping @Sendable (Selection?) -> (
            entityName: String,
            primaryKey: String
        )?
    ) -> some View {
        modifier(PreviewSnapshotModifier(
            selection: selection,
            makePersistentIdentifier: makePersistentIdentifier
        ))
    }
}

// FIXME: Geometry implementation causes view to be centered rather than bottom.

struct PreviewSnapshotModifier<Selection: Hashable & Sendable>: ViewModifier {
    @DatabaseActor @Environment(Database.self) private var database
    @Environment(\.modelContext) private var modelContext
    @State private var snapshot: DatabaseSnapshot?
    @State private var isDragging: Bool = false
    @State private var containerSize: CGSize?
    @Binding var selection: Selection?
    nonisolated let makePersistentIdentifier:
    @Sendable (Selection?) -> (entityName: String, primaryKey: String)?
    
    func body(content: Content) -> some View {
        content
            .overlay {
                Rectangle()
                    .hidden()
                    .onGeometryChange(for: CGSize.self, of: \.size) { _, newValue in
                        self.containerSize = newValue
                    }
            }
            .scaleEffect(isDragging ? 0.9 : 1.0, anchor: .center)
            .scrollDisabled(isDragging)
            .overlay(alignment: .bottom) {
                Panel(
                    selection: $selection,
                    snapshot: $snapshot,
                    isDragging: $isDragging,
                    size: containerSize,
                    makePersistentIdentifier: { makePersistentIdentifier($0) }
                )
            }
            .animation(.spring, value: selection)
    }
    
    struct Panel: View {
        @Environment(Database.self) private var database
        @State private var offset: CGSize = .zero
        @State private var containerSize: CGSize?
        @Binding var selection: Selection?
        @Binding var snapshot: DatabaseSnapshot?
        @Binding var isDragging: Bool
        var size: CGSize?
        nonisolated let makePersistentIdentifier:
        @Sendable (Selection?) -> (entityName: String, primaryKey: String)?
        
        private var maximumHeight: CGFloat {
            max(0, (size?.height ?? 0) - 25)
        }
        
        private var panelHeight: CGFloat? {
            guard let containerSize else { return nil }
            return min(containerSize.height + 32, maximumHeight)
        }
        
        var body: some View {
            if let selection = self.selection {
                VStack {
                    if let snapshot = self.snapshot {
                        ScrollView {
                            VStack(spacing: 24) {
                                ZStack(alignment: .trailing) {
                                    HeaderView(
                                        entityName: snapshot.entityName,
                                        offset: $offset,
                                        isDragging: $isDragging
                                    )
                                    Button("Close") {
                                        withAnimation(.spring(duration: 0.3)) {
                                            self.selection = nil
                                            self.snapshot = nil
                                        }
                                    }
                                }
                                DatabaseRecordView(snapshot: snapshot)
                                    .foregroundStyle(.primary, Color.accentColor)
                            }
                            .onGeometryChange(for: CGSize.self, of: \.size) { _, newValue in
                                self.containerSize = newValue
                            }
                        }
                    } else {
                        ProgressView()
                    }
                }
                .padding()
                .background(in: .rect(cornerRadius: 25))
                .frame(maxWidth: 400)
                .frame(height: panelHeight, alignment: .bottom)
                .frame(maxHeight: maximumHeight, alignment: .bottom)
                .safeAreaPadding()
                .shadow(radius: 12)
                .offset(x: offset.width, y: offset.height)
                .transition(.blurReplace)
                .task(id: selection) { @DatabaseActor in
                    if let selected = makePersistentIdentifier(selection) {
                        let snapshot = try? await database.withDataStore { store in
                            let identifier = try PersistentIdentifier.identifier(
                                for: store.identifier,
                                entityName: selected.entityName,
                                primaryKey: selected.primaryKey
                            )
                            var relatedSnapshots: [PersistentIdentifier: DatabaseStore.Snapshot]? =
                            [PersistentIdentifier: DatabaseStore.Snapshot]()
                            if let type = Schema.type(for: selected.entityName) {
                                return try store.fetch(
                                    for: identifier,
                                    as: type,
                                    relatedSnapshots: &relatedSnapshots
                                )
                            } else {
                                return nil
                            }
                        }
                        await MainActor.run {
                            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                                self.snapshot = snapshot
                            }
                        }
                    }
                }
            }
        }
        
        struct HeaderView: View {
            @GestureState private var drag: CGSize = .zero
            var entityName: String
            @Binding var offset: CGSize
            @Binding var isDragging: Bool
            
            var body: some View {
                Text(entityName)
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .contentShape(.rect)
                    .onTapGesture(count: 2) {
                        withAnimation(.spring) {
                            offset.width = 0
                            offset.height = 0
                        }
                    }
                    .gesture(
                        DragGesture()
                            .updating($drag) { value, state, _ in
                                if !isDragging {
                                    withAnimation { self.isDragging = true }
                                }
                                offset.width += value.translation.width
                                offset.height += value.translation.height
                            }
                            .onEnded { _ in
                                withAnimation { self.isDragging = false }
                            }
                    )
                    .animation(.default, value: drag)
            }
        }
    }
}
