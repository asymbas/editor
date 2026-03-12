//
//  Schema.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftData
import SwiftUI

struct DefaultSchema: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [Entity.self]
//        + TypeSchema.models
        + FeatureSchema.models
        + SampleSchema.models
//        + RelationshipSchema.models
//        + InheritanceSchema.models
//        + MigrationSchema.Active.models
    }
    
    static var versionIdentifier: Schema.Version {
        .init(0, 0, 0)
    }
}

@Model class Entity {
    #Unique<Entity>([\.id])
    #Index<Entity>([\.id])
    
    @Attribute(.unique) var id: String
    @Attribute var test: String?
    
    @Transient var isSelected: Bool = false
    
    @Transient lazy var count: Int = {
        .random(in: 0...100)
    }()
    
    init(id: String = UUID().uuidString) {
        self.id = id
    }
}
