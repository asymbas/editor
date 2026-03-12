//
//  PredicateVariant.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreSupport
import Foundation
import SwiftData
import SwiftUI

struct PredicateVariant<Model>: Identifiable where Model: PersistentModel {
    let id: UUID = .init()
    var title: String
    var description: String?
    var expectations: QueryRun.Expectations
    var seed: SeedAction?
    
    init(
        _ title: String,
        description: String? = nil,
        expectations: [QueryRun.Expectations.Rule],
        seed: SeedAction? = nil
    ) {
        self.title = title
        self.description = description
        self.expectations = QueryRun.Expectations.build(expectations)
        self.seed = seed
    }
    
    init(
        _ title: String,
        description: String? = nil,
        expectations: QueryRun.Expectations.Rule...,
        seed: SeedAction? = nil
    ) {
        self.init(
            title,
            description: description,
            expectations: expectations,
            seed: seed
        )
    }
}

extension PredicateVariant {
    init(
        _ title: String,
        description: String? = nil,
        expectations: [QueryRun.Expectations.Rule],
        seed: [SeedOperation]
    ) {
        self.init(
            title,
            description: description,
            expectations: expectations,
            seed: { context in try SeedExecutor.run(seed, in: context) }
        )
    }
    
    init(
        _ title: String,
        description: String? = nil,
        expectations: [QueryRun.Expectations.Rule],
        @SeedBuilder seed: @escaping @DatabaseActor () -> [SeedOperation]
    ) {
        self.init(
            title,
            description: description,
            expectations: expectations,
            seed: QueryRun.seed(seed)
        )
    }
    
    init(
        _ title: String,
        description: String? = nil,
        expectations: [QueryRun.Expectations.Rule],
        @SeedBuilder seed: @escaping @DatabaseActor (ModelContext) -> [SeedOperation]
    ) {
        self.init(
            title,
            description: description,
            expectations: expectations,
            seed: QueryRun.seed(seed)
        )
    }
    
    init(
        _ title: String,
        description: String? = nil,
        expectations: QueryRun.Expectations.Rule...,
        seed: [SeedOperation]
    ) {
        self.init(title, description: description, expectations: expectations, seed: seed)
    }
    
    init(
        _ title: String,
        description: String? = nil,
        expectations: QueryRun.Expectations.Rule...,
        @SeedBuilder seed: @escaping @DatabaseActor () -> [SeedOperation]
    ) {
        self.init(title, description: description, expectations: expectations, seed: seed)
    }
    
    init(
        _ title: String,
        description: String? = nil,
        expectations: QueryRun.Expectations.Rule...,
        @SeedBuilder seed: @escaping @DatabaseActor (ModelContext) -> [SeedOperation]
    ) {
        self.init(title, description: description, expectations: expectations, seed: seed)
    }
}
