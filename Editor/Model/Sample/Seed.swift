//
//  Seed.swift
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

@MainActor func seedDefaultValues(
    into modelContext: ModelContext,
    types models: [any PersistentModel.Type]
) {
    for type in models {
        guard let type = type as? any (DefaultInitializer & PersistentModel).Type else {
            continue
        }
        do {
            if try modelContext.fetch(all: type).isEmpty {
                modelContext.insert(type.init())
            }
        } catch {
            Banner.error("Fetch Error") {
                "Failed to seed \(type) model: \(error)"
            }
        }
    }
}

@MainActor func seedSampleData(
    into modelContext: ModelContext,
    force: Bool = false
) async throws {
    seedDefaultValues(into: modelContext, types: TypeSchema.models)
    let entity = Entity()
    entity.id = "entity"
    modelContext.insert(entity)
    try await FeatureSchema.seed(into: modelContext)
    let hasAnyRelationshipModels: Bool = {
        do {
            for type in SampleSchema.models {
                if try modelContext.fetch(all: type).isEmpty == false {
                    return true
                }
            }
            return false
        } catch {
            Banner(.error, "Fetch Error") {
                "Failed to seed model: \(error)"
            }
            return false
        }
    }()
    guard force || !hasAnyRelationshipModels else { return }
    try await SampleSchema.seed(into: modelContext)
}
