//
//  SeedBuilder.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreSupport
import Foundation
import SwiftData

typealias SeedAction = @DatabaseActor (ModelContext) throws -> Void

@DatabaseActor @resultBuilder enum SeedBuilder {
    static func buildBlock(_ components: [SeedOperation]...) -> [SeedOperation] {
        components.flatMap(\.self)
    }
    
    static func buildExpression(_ expression: SeedOperation) -> [SeedOperation] {
        [expression]
    }
    
    @DatabaseActor
    static func buildExpression<T: PersistentModel>(_ expression: T) -> [SeedOperation] {
        [.insert(expression)]
    }
    
    @DatabaseActor
    static func buildExpression<T: PersistentModel>(_ expression: T?) -> [SeedOperation] {
        guard let expression else { return [] }
        return [.insert(expression)]
    }
    
    @DatabaseActor
    static func buildExpression<S: Sequence>(_ expression: S) -> [SeedOperation]
    where S.Element: PersistentModel {
        expression.map { .insert($0) }
    }
    
    static func buildExpression(_ expression: Void) -> [SeedOperation] {
        []
    }
    
    static func buildOptional(_ component: [SeedOperation]?) -> [SeedOperation] {
        component ?? []
    }
    
    static func buildEither(first: [SeedOperation]) -> [SeedOperation] {
        first
    }
    
    static func buildEither(second: [SeedOperation]) -> [SeedOperation] {
        second
    }
    
    static func buildArray(_ components: [[SeedOperation]]) -> [SeedOperation] {
        components.flatMap(\.self)
    }
    
    static func buildFinalResult(_ component: [SeedOperation]) -> [SeedOperation] {
        component
    }
}

struct SeedState {
    fileprivate var seen: Set<AnyHashable> = []
    init() {}
}

struct SeedOperation {
    @DatabaseActor
    fileprivate let run: @DatabaseActor (ModelContext, inout SeedState) throws -> Void
    
    @DatabaseActor
    static func insert<T: PersistentModel>(
        _ model: T,
        key: (any Hashable & Sendable)? = nil
    ) -> Self {
        Self { context, state in
            let key = key ?? ObjectIdentifier(model)
            guard state.seen.insert(key).inserted else { return }
            context.insert(model)
        }
    }
    
    @DatabaseActor
    static func insertIfMissing<T: PersistentModel>(
        _ make: @autoclosure @escaping () -> T,
        predicate: Predicate<T>
    ) -> Self {
        Self { modelContext, state in
            let existing = try modelContext.fetch(FetchDescriptor<T>(predicate: predicate))
            guard existing.isEmpty else { return }
            let model = make()
            let k: AnyHashable = AnyHashable(ObjectIdentifier(model))
            guard state.seen.insert(k).inserted else { return }
            modelContext.insert(model)
        }
    }
    
    @DatabaseActor
    static func once(
        _ key: AnyHashable,
        _ body: @escaping (ModelContext) throws -> Void
    ) -> Self {
        Self { modelContext, state in
            guard state.seen.insert(key).inserted else { return }
            try body(modelContext)
        }
    }
    
    @DatabaseActor
    static func action(_ body: @escaping (ModelContext) throws -> Void) -> Self {
        Self { context, _ in try body(context) }
    }
}

enum SeedExecutor {
    @DatabaseActor
    static func run(_ steps: [SeedOperation], in modelContext: ModelContext) throws {
        var state = SeedState()
        for step in steps {
            try step.run(modelContext, &state)
        }
    }
}

extension QueryRun {
    nonisolated
    static func seed(_ build: [SeedOperation]) -> SeedAction {
        { modelContext in try SeedExecutor.run(build, in: modelContext) }
    }
    
    nonisolated
    static func seed(@SeedBuilder _ build: @escaping @DatabaseActor () -> [SeedOperation]) -> SeedAction {
        { modelContext in try SeedExecutor.run(build(), in: modelContext) }
    }
    
    nonisolated
    static func seed(@SeedBuilder _ build: @escaping @DatabaseActor (ModelContext) -> [SeedOperation]) -> SeedAction {
        { modelContext in try SeedExecutor.run(build(modelContext), in: modelContext) }
    }
}
