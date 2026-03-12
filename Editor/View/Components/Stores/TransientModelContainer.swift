//
//  TransientModelContainer.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreCore
import DataStoreKit
import DataStoreSupport
import Logging
import SwiftData
import SwiftUI

@Observable private final class Model: Sendable {
    @DatabaseActor private var providers: [ObjectIdentifier: DatabaseProvider] = [:]
    @DatabaseActor private var observers: [ObjectIdentifier: Int] = [:]
    
    nonisolated init() {}
    
    @DatabaseActor func register(
        schema: Schema,
        attachment: (any DataStoreDelegate)?
    ) throws -> DatabaseProvider {
        let id = ObjectIdentifier(schema)
        switch providers[id] {
        case let provider?:
            observers[id, default: 0] += 1
            return provider
        case nil:
            let configuration = DatabaseConfiguration(
                transient: (),
                options: .disableSnapshotCaching,
                attachment: attachment
            )
            let modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            let provider = DatabaseProvider(
                schema: schema,
                configuration: configuration,
                modelContainer: modelContainer
            )
            observers[id, default: 0] += 1
            providers[id] = provider
            return provider
        }
    }
    
    @DatabaseActor func unregister(schema: Schema) {
        let id = ObjectIdentifier(schema)
        guard var count = observers[id], count > 0 else {
            return
        }
        count -= 1
        observers[id] = count
        guard count == 0 else {
            return
        }
        _ = providers.removeValue(forKey: id)
    }
}

private struct ModelKey: EnvironmentKey {
    nonisolated static let defaultValue: Model = .init()
}

extension EnvironmentValues {
    fileprivate var model: Model {
        get { self[ModelKey.self] }
        set { self[ModelKey.self] = newValue }
    }
}

extension View {
    func withTransientModelContainer<Model>(of types: [Model.Type]) -> some View
    where Model: PersistentModel {
        modifier(TransientModelContainerModifier(types: types))
    }
}

struct TransientModelContainerModifier: ViewModifier {
    @DatabaseActor @Environment(Observer.self) private var observer
    @DatabaseActor @Environment(\.model) private var view
    @DatabaseActor @Environment(\.schema) private var schema
    @Environment(\.modelContext) private var modelContext
    
    @State private var provider: DatabaseProvider?
    var types: [any PersistentModel.Type]
    
    func body(content: Content) -> some View {
        VStack {
            content
                .disabled(provider == nil)
                .modelContainer(provider?.modelContainer ?? modelContext.container)
        }
        .task {
            guard self.provider == nil else {
                return
            }
            do {
                let provider = try await DatabaseActor.run {
                    let schema = types.isEmpty ? schema : Schema(types)
                    let provider = try view.register(schema: schema, attachment: observer)
                    return provider
                }
                await MainActor.run {
                    self.provider = provider
                }
            } catch {
                logger.error("Unable to create database for testing: \(error)")
            }
        }
        .onDisappear {
            guard let provider = self.provider.take() else {
                return
            }
            Task { @DatabaseActor in
                view.unregister(schema: provider.schema)
            }
        }
    }
}
