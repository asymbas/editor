//
//  RelationshipSchema.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftData

struct RelationshipSchema: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [
            CardinalityTestDependencyCycle.AssociatedEntity.self,
            CardinalityTestDependencyCycle.AssociatedEntity.LHS.self,
            CardinalityTestDependencyCycle.AssociatedEntity.RHS.self
        ]
    }
    
    static var versionIdentifier: Schema.Version {
        .init(0, 0, 0)
    }
    
    static func seed(
        into modelContext: ModelContext,
        isolation: isolated Actor = #isolation
    ) async throws {
        try modelContext.transaction {
            let lhs = CardinalityTestDependencyCycle.AssociatedEntity.LHS(id: "lhs")
            let rhs = CardinalityTestDependencyCycle.AssociatedEntity.RHS(id: "rhs")
            let entity = CardinalityTestDependencyCycle.AssociatedEntity(
                id: "intermediary",
                lhs: lhs,
                rhs: rhs
            )
            modelContext.insert(entity)
        }
    }
}

enum CardinalityTestDependencyCycle {
    @Model class AssociatedEntity {
        @Attribute(.unique, .preserveValueOnDeletion) var id: String
        
        @Relationship(inverse: \LHS.intermediary)
        var lhs: LHS
        
        @Relationship(inverse: \RHS.intermediary)
        var rhs: RHS
        
        init(
            id: String = UUID().uuidString,
            lhs: LHS,
            rhs: RHS
        ) {
            self.id = id
            self.lhs = lhs
            self.rhs = rhs
        }
        
        @Model class LHS {
            @Attribute(.unique) var id: String
            
            @Relationship(deleteRule: .cascade)
            var intermediary: [AssociatedEntity]
            
            init(
                id: String = UUID().uuidString,
                intermediary: [AssociatedEntity] = []
            ) {
                self.id = id
                self.intermediary = intermediary
            }
        }
        
        @Model class RHS {
            @Attribute(.unique) var id: String
            
            @Relationship(deleteRule: .cascade)
            var intermediary: [AssociatedEntity]
            
            init(
                id: String = UUID().uuidString,
                intermediary: [AssociatedEntity] = []
            ) {
                self.id = id
                self.intermediary = intermediary
            }
        }
    }
}
