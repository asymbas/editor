//
//  InheritanceSchema.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftData

#if swift(>=6.2)

@available(iOS 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0, *)
struct InheritanceSchema: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [
            Person.self
        ]
    }
    
    static var versionIdentifier: Schema.Version {
        .init(0, 0, 0)
    }
    
    static func seed(
        into modelContext: ModelContext,
        isolation: isolated Actor = #isolation
    ) async throws {
        let person = Person(name: "Anferne Pineda")
        modelContext.insert(person)
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0, *)
@Model class Person: Entity {
    @Attribute var name: String
    
    init(name: String) {
        self.name = name
        super.init()
    }
}

#endif
