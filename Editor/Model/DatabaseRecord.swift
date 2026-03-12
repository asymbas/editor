//
//  DatabaseRecord.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import DataStoreRuntime
import Foundation

#if swift(>=6.2)
import SwiftData
#else
@preconcurrency import SwiftData
#endif

@MainActor @Observable class DatabaseRecord: Identifiable {
    nonisolated let entity: Schema.Entity
    nonisolated let snapshot: DatabaseSnapshot
    let model: any PersistentModel
    let systemImage: String
    
    init<Model: PersistentModel>(model: Model, entity: Schema.Entity) {
        self.entity = entity
        let snapshot = DatabaseSnapshot(model)
        self.model = model
        self.snapshot = snapshot
        self.systemImage = (Model.self as? any SystemImageNameProviding.Type)?.systemImage
        ?? "circle"
    }
    
    nonisolated var id: PersistentIdentifier {
        snapshot.persistentIdentifier
    }
    
    @ObservationIgnored lazy var makeAlignedPairs: [PropertyValuePair] = {
        []
    }()
}

struct PropertyValuePair: Hashable {
    let property: PropertyMetadata
    let value: any DataStoreSnapshotValue
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.property == rhs.property
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(property)
    }
}

struct DatabaseRelationshipReference: Hashable, Identifiable {
    let sourceEntityName: String
    let relationshipName: String
    let destinationEntityName: String
    let persistentIdentifier: PersistentIdentifier
    let cardinality: (RelationshipCardinality, RelationshipCardinality)
    
    var id: String {
        let name = "\(sourceEntityName).\(relationshipName)"
        return "\(name).\(persistentIdentifier.primaryKey())"
    }
    
    var detailedDescription: [String] {
        [cardinality.0.detailedDescription, cardinality.1.detailedDescription]
    }
    
    var cardinalityDescription: [String] {
        [cardinality.0.cardinalityDescription, cardinality.1.cardinalityDescription]
    }
    
    enum RelationshipCardinality: Hashable {
        case required(Cardinality)
        case optional(Cardinality)
        
        enum Cardinality: String, Hashable {
            case one
            case many
            case unknown
        }
        
        var detailedDescription: String {
            switch self {
            case .optional(let value): "Optional \(value.rawValue)"
            case .required(let value): "Required \(value.rawValue)"
            }
        }
        
        var cardinalityDescription: String {
            switch self {
            case .optional(let value): value.rawValue
            case .required(let value): value.rawValue
            }
        }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
