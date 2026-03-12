//
//  PredicateTest.swift
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

struct PredicateTest<Model>: View where Model: PersistentModel {
    @Environment(Observer.self) private var observer
    @State private var provider: DatabaseProvider?
    private var title: String
    private var description: String?
    private var types: [any PersistentModel.Type]
    private var expectations: QueryRun.Expectations
    private var seed: SeedAction?
    private var predicate: Predicate<Model>
    
    var body: some View {
        VStack {
            if let modelContainer = self.provider?.modelContainer {
                QueryTest(
                    title,
                    description: description,
                    expectations: expectations,
                    seed: seed
                ) {
                    FetchDescriptor<Model>(predicate: predicate, sortBy: [])
                }
                .modelContainer(modelContainer)
                .environment(\.resetBeforeRun, true)
                .transition(.scale)
            } else {
                ProgressView("Loading")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.scale)
                    .task {
                        guard self.provider == nil else {
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
                            }
                        } catch {
                            logger.error("Unable to create database for testing: \(error)")
                        }
                    }
            }
        }
        .animation(.spring, value: provider == nil)
    }
}

extension PredicateTest {
    init(
        _ title: String,
        description: String? = nil,
        types: [any PersistentModel.Type] = [Model.self],
        provider: DatabaseProvider? = nil,
        expectations: QueryRun.Expectations,
        seed: SeedAction? = nil,
        predicate: Predicate<Model>
    ) {
        self.title = title
        self.description = description
        self.types = types
        self.provider = provider
        self.expectations = expectations
        self.seed = seed
        self.predicate = predicate
    }
    
    init(
        _ title: String,
        description: String? = nil,
        types: [any PersistentModel.Type] = [Model.self],
        provider: @autoclosure @escaping () -> DatabaseProvider? = nil,
        expectations: [QueryRun.Expectations.Rule],
        seed: SeedAction? = nil,
        predicate: Predicate<Model>
    ) {
        self.init(
            title,
            description: description,
            types: types,
            provider: provider(),
            expectations: QueryRun.Expectations.build(expectations),
            seed: seed,
            predicate: predicate
        )
    }
    
    init(
        _ title: String,
        description: String? = nil,
        types: [any PersistentModel.Type] = [Model.self],
        provider: @autoclosure @escaping () -> DatabaseProvider? = nil,
        expectations: QueryRun.Expectations.Rule...,
        seed: SeedAction? = nil,
        predicate: Predicate<Model>
    ) {
        self.init(
            title,
            description: description,
            types: types,
            provider: provider(),
            expectations: expectations,
            seed: seed,
            predicate: predicate
        )
    }
}

extension PredicateTest {
    init(
        _ title: String,
        description: String? = nil,
        types: [any PersistentModel.Type] = [Model.self],
        provider: DatabaseProvider? = nil,
        expectations: QueryRun.Expectations,
        seed: @autoclosure @escaping @DatabaseActor () -> [SeedOperation],
        predicate: Predicate<Model>
    ) {
        self.init(
            title,
            description: description,
            types: types,
            provider: provider,
            expectations: expectations,
            seed: { context in try SeedExecutor.run(seed(), in: context) },
            predicate: predicate
        )
    }

    init(
        _ title: String,
        description: String? = nil,
        types: [any PersistentModel.Type] = [Model.self],
        provider: DatabaseProvider? = nil,
        expectations: QueryRun.Expectations,
        @SeedBuilder seed: @escaping @DatabaseActor () -> [SeedOperation],
        predicate: Predicate<Model>
    ) {
        self.init(
            title,
            description: description,
            types: types,
            provider: provider,
            expectations: expectations,
            seed: QueryRun.seed(seed),
            predicate: predicate
        )
    }

    init(
        _ title: String,
        description: String? = nil,
        types: [any PersistentModel.Type] = [Model.self],
        provider: DatabaseProvider? = nil,
        expectations: QueryRun.Expectations,
        @SeedBuilder seed: @escaping @DatabaseActor (ModelContext) -> [SeedOperation],
        predicate: Predicate<Model>
    ) {
        self.init(
            title,
            description: description,
            types: types,
            provider: provider,
            expectations: expectations,
            seed: QueryRun.seed(seed),
            predicate: predicate
        )
    }

    init(
        _ title: String,
        description: String? = nil,
        types: [any PersistentModel.Type] = [Model.self],
        provider: @autoclosure @escaping () -> DatabaseProvider? = nil,
        expectations: [QueryRun.Expectations.Rule],
        seed: @autoclosure @escaping @DatabaseActor () -> [SeedOperation],
        predicate: Predicate<Model>
    ) {
        self.init(
            title,
            description: description,
            types: types,
            provider: provider(),
            expectations: QueryRun.Expectations.build(expectations),
            seed: seed,
            predicate: predicate
        )
    }

    init(
        _ title: String,
        description: String? = nil,
        types: [any PersistentModel.Type] = [Model.self],
        provider: @autoclosure @escaping () -> DatabaseProvider? = nil,
        expectations: [QueryRun.Expectations.Rule],
        @SeedBuilder seed: @escaping @DatabaseActor () -> [SeedOperation],
        predicate: Predicate<Model>
    ) {
        self.init(
            title,
            description: description,
            types: types,
            provider: provider(),
            expectations: QueryRun.Expectations.build(expectations),
            seed: seed,
            predicate: predicate
        )
    }

    init(
        _ title: String,
        description: String? = nil,
        types: [any PersistentModel.Type] = [Model.self],
        provider: @autoclosure @escaping () -> DatabaseProvider? = nil,
        expectations: [QueryRun.Expectations.Rule],
        @SeedBuilder seed: @escaping @DatabaseActor (ModelContext) -> [SeedOperation],
        predicate: Predicate<Model>
    ) {
        self.init(
            title,
            description: description,
            types: types,
            provider: provider(),
            expectations: QueryRun.Expectations.build(expectations),
            seed: seed,
            predicate: predicate
        )
    }

    init(
        _ title: String,
        description: String? = nil,
        types: [any PersistentModel.Type] = [Model.self],
        provider: @autoclosure @escaping () -> DatabaseProvider? = nil,
        expectations: QueryRun.Expectations.Rule...,
        seed: @autoclosure @escaping @DatabaseActor () -> [SeedOperation],
        predicate: Predicate<Model>
    ) {
        self.init(
            title,
            description: description,
            types: types,
            provider: provider(),
            expectations: expectations,
            seed: seed,
            predicate: predicate
        )
    }

    init(
        _ title: String,
        description: String? = nil,
        types: [any PersistentModel.Type] = [Model.self],
        provider: @autoclosure @escaping () -> DatabaseProvider? = nil,
        expectations: QueryRun.Expectations.Rule...,
        @SeedBuilder seed: @escaping @DatabaseActor () -> [SeedOperation],
        predicate: Predicate<Model>
    ) {
        self.init(
            title,
            description: description,
            types: types,
            provider: provider(),
            expectations: expectations,
            seed: seed,
            predicate: predicate
        )
    }

    init(
        _ title: String,
        description: String? = nil,
        types: [any PersistentModel.Type] = [Model.self],
        provider: @autoclosure @escaping () -> DatabaseProvider? = nil,
        expectations: QueryRun.Expectations.Rule...,
        @SeedBuilder seed: @escaping @DatabaseActor (ModelContext) -> [SeedOperation],
        predicate: Predicate<Model>
    ) {
        self.init(
            title,
            description: description,
            types: types,
            provider: provider(),
            expectations: expectations,
            seed: seed,
            predicate: predicate
        )
    }
}
