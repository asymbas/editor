//
//  PredicateTestStack.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreCore
import DataStoreKit
import DataStoreRuntime
import DataStoreSupport
import Logging
import SwiftData
import SwiftUI

struct PredicateTestStack<Model: PersistentModel>: View {
    @Environment(Observer.self) private var observer
    @State private var provider: DatabaseProvider?
    @State private var modelContext: ModelContext?
    private var title: String
    private var description: String?
    private var types: [any PersistentModel.Type]
    private var predicate: Predicate<Model>
    private var variants: [PredicateVariant<Model>]
    private var resetBeforeRun: Bool
    
    init(
        _ title: String,
        description: String? = nil,
        resetBeforeRun: Bool = true,
        types: [any PersistentModel.Type] = [Model.self],
        provider: @autoclosure @escaping () -> DatabaseProvider? = nil,
        predicate: Predicate<Model>,
        @PredicateVariantBuilder<Model> variants: () -> [PredicateVariant<Model>]
    ) {
        self.title = title
        self.description = description
        self.types = types
        self.predicate = predicate
        self.resetBeforeRun = resetBeforeRun
        self.provider = provider()
        self.variants = variants()
    }
    
    var body: some View {
        VStack {
            if let provider = self.provider,
               let modelContext = self.modelContext {
                PredicateGroupCard(
                    title: title,
                    description: description,
                    count: variants.count
                ) {
                    VStack(spacing: 20) {
                        ForEach(variants) { variant in
                            PredicateVariantCard(
                                modelContext: modelContext,
                                parentTitle: title,
                                parentDescription: description,
                                variant: variant,
                                predicate: predicate
                            )
                        }
                    }
                }
                .environment(\.schema, provider.schema)
                .modelContainer(provider.modelContainer)
                .transition(.scale)
            } else {
                ProgressView("Loading")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.scale)
                    .task {
                        if let provider = self.provider, self.modelContext == nil {
                            self.modelContext = ModelContext(provider.modelContainer)
                            return
                        }
                        guard provider == nil else {
                            return
                        }
                        do {
                            let observer = self.observer
                            let provider = try await DatabaseActor.run {
                                let schema = Schema(types)
                                let configuration = DatabaseConfiguration(
                                    transient: (),
                                    options: .disableSnapshotCaching,
                                    attachment: observer
                                )
                                let modelContainer = try ModelContainer(
                                    for: schema,
                                    configurations: [configuration]
                                )
                                return DatabaseProvider(
                                    schema: schema,
                                    configuration: configuration,
                                    modelContainer: modelContainer
                                )
                            }
                            await MainActor.run {
                                self.provider = provider
                                self.modelContext = ModelContext(provider.modelContainer)
                            }
                        } catch {
                            logger.error("Unable to create database: \(error)")
                        }
                    }
            }
        }
        .animation(.spring, value: provider == nil)
    }
    
    struct PredicateVariantCard: View {
        var modelContext: ModelContext
        var parentTitle: String
        var parentDescription: String?
        var variant: PredicateVariant<Model>
        var predicate: Predicate<Model>
        
        var body: some View {
            QueryTest<Model>(
                variant.title,
                description: variant.description ?? parentDescription,
                expectations: variant.expectations,
                seed: variant.seed
            ) {
                FetchDescriptor<Model>(predicate: predicate, sortBy: [])
            }
            .environment(\.modelContext, modelContext)
        }
    }
    
    struct PredicateGroupCard<Content>: View where Content: View {
        @Environment(\.colorScheme) private var colorScheme
        var title: String
        var description: String?
        var count: Int
        @ViewBuilder var content: Content
        
        var body: some View {
            VStack(alignment: .leading, spacing: 14) {
                HeaderView(title, description: description, count: count)
                content
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: backgroundColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
            )
            .shadow(radius: 12, y: 6)
        }
        
        struct HeaderView: View {
            private var title: String
            private var description: String?
            private var icon: Image
            private var count: Int
            
            init(
                _ title: String,
                description: String? = nil,
                count: Int
            ) {
                self.title = title
                self.description = description
                self.count = count
                if let type = Model.self as? any SystemImageNameProviding.Type {
                    self.icon = Image(systemName: type.systemImage)
                } else {
                    self.icon = Image(systemName: "square.stack.3d.up.fill")
                }
            }
            
            var body: some View {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    icon
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(LocalizedStringKey(title))
                            .font(.headline)
                        HStack(spacing: 8) {
                            Text("\(count) variants")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            if let description = self.description {
                                Text(LocalizedStringKey(description))
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
        
        private var backgroundColors: [Color] {
            switch colorScheme {
            case .light:
                [
                    Color.indigo.opacity(0.18),
                    Color.purple.opacity(0.10),
                    .base
                ]
            case .dark:
                [
                    Color.indigo.opacity(0.35),
                    Color.purple.opacity(0.20),
                    .baseSecondary
                ]
            @unknown default:
                fatalError()
            }
        }
    }
}
