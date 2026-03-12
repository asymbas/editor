//
//  SchemaWorkbench.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftData
import SwiftUI

enum SchemaWorkbench {
    struct Summary: Hashable {
        var entities: Int
        var attributes: Int
        var relationships: Int
        var indices: Int
        var uniquenessConstraints: Int
        
        static func run(schema: Schema) -> Summary {
            var attributeCount = 0
            var relationshipCount = 0
            var indexCount = 0
            var uniqueCount = 0
            for entity in schema.entities {
                indexCount += entity.indices.count
                uniqueCount += entity.uniquenessConstraints.count
                attributeCount += entity.attributes.count
                relationshipCount += entity.relationships.count
            }
            return .init(
                entities: schema.entities.count,
                attributes: attributeCount,
                relationships: relationshipCount,
                indices: indexCount,
                uniquenessConstraints: uniqueCount
            )
        }
    }
    
    enum Severity: String, Hashable {
        case error
        case warning
        case info
        
        var systemImage: String {
            switch self {
            case .error: "xmark.octagon.fill"
            case .warning: "exclamationmark.triangle.fill"
            case .info: "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .error: .red
            case .warning: .yellow
            case .info: .secondary
            }
        }
    }
    
    struct Issue: Hashable, Identifiable {
        var severity: Severity
        var code: Code
        var entityName: String?
        var relationshipName: String?
        var description: String
        
        var id: String {
            let entityName = self.entityName ?? "-"
            let relationshipName = self.relationshipName ?? "-"
            let key = self.severity.rawValue + ":" + self.code.rawValue
            return "\(key):\(entityName):\(relationshipName)"
        }
        
        static func run(schema: Schema) -> [Issue] {
            var issues = [Issue]()
            let entitiesByName = schema.entitiesByName
            let incoming = IncomingEdge.run(schema: schema)
            for entity in schema.entities {
                for index in entity.indices {
                    for column in index
                    where entity.storedPropertiesByName[column] == nil {
                        issues.append(.init(
                            severity: .error,
                            code: .indexMissingColumn,
                            entityName: entity.name,
                            description: "Index references missing property `\(column)`."
                        ))
                    }
                }
                for uniquenessConstraint in entity.uniquenessConstraints {
                    for propertyName in uniquenessConstraint
                    where entity.storedPropertiesByName[propertyName] == nil {
                        issues.append(.init(
                            severity: .error,
                            code: .uniqueMissingColumn,
                            entityName: entity.name,
                            description: "Unique constraint references missing property `\(propertyName)`."
                        ))
                    }
                }
                for relationship in entity.relationships {
                    if entitiesByName[relationship.destination] == nil {
                        issues.append(.init(
                            severity: .error,
                            code: .relationshipDestinationMissing,
                            entityName: entity.name,
                            relationshipName: relationship.name,
                            description: "Destination entity `\(relationship.destination)` not found in schema."
                        ))
                    }
                    if let inverseCandidates = entitiesByName[relationship.destination] {
                        let inverseRelationships = inverseCandidates.relationships.filter {
                            $0.destination == entity.name
                        }
                        if inverseRelationships.isEmpty {
                            if relationship.isToOneRelationship {
                                issues.append(.init(
                                    severity: .warning,
                                    code: .toOneUnidirectional,
                                    entityName: entity.name,
                                    relationshipName: relationship.name,
                                    description: "To-one relationship has no obvious inverse on `\(relationship.destination)`."
                                ))
                            } else {
                                issues.append(.init(
                                    severity: .info,
                                    code: .toManyUnidirectional,
                                    entityName: entity.name,
                                    relationshipName: relationship.name,
                                    description: "To-many relationship has no obvious inverse on `\(relationship.destination)`."
                                ))
                            }
                        } else if inverseRelationships.count > 1 {
                            issues.append(.init(
                                severity: .warning,
                                code: .ambiguousInverse,
                                entityName: entity.name,
                                relationshipName: relationship.name,
                                description: "Multiple inverse candidates on `\(relationship.destination)` point back to `\(entity.name)`."
                            ))
                        } else {
                            guard let inverseRelationship = inverseRelationships.first else {
                                continue
                            }
                            if relationship.deleteRule == .cascade
                                && inverseRelationship.deleteRule == .cascade {
                                issues.append(.init(
                                    severity: .warning,
                                    code: .cascadeCyclePair,
                                    entityName: entity.name,
                                    relationshipName: relationship.name,
                                    description: "Deleting either will delete the other."
                                ))
                            }
                        }
                    }
                    if let incomingEdges = incoming[entity.name],
                       relationship.deleteRule == .deny,
                       incomingEdges.contains(where: { $0.source == relationship.destination }) {
                        issues.append(.init(
                            severity: .info,
                            code: .deniedByIncomingReferences,
                            entityName: entity.name,
                            relationshipName: relationship.name,
                            description: "Deny rule exists and there are incoming references. Deletes may be blocked."
                        ))
                    }
                }
            }
            issues.sort {
                if $0.severity != $1.severity {
                    let rank: (Severity) -> Int = { severity in
                        switch severity {
                        case .error: 0
                        case .warning: 1
                        case .info: 2
                        }
                    }
                    return rank($0.severity) < rank($1.severity)
                }
                if ($0.entityName ?? "") != ($1.entityName ?? "") {
                    return ($0.entityName ?? "") < ($1.entityName ?? "")
                } else {
                    return $0.code.rawValue < $1.code.rawValue
                }
            }
            return issues
        }
        
        enum Code: String, Hashable {
            case ambiguousInverse = "ambiguous_inverse"
            case cascadeCyclePair = "cascade_cycle_pair"
            case deniedByIncomingReferences = "denied_by_incoming_references"
            case indexMissingColumn = "index_missing_column"
            case relationshipDestinationMissing = "relationship_destination_missing"
            case toManyUnidirectional = "to_many_unidirectional"
            case toOneUnidirectional = "to_one_unidirectional"
            case uniqueMissingColumn = "unique_missing_column"
        }
    }
    
    struct Scenario: Identifiable {
        let id: UUID = .init()
        var title: String
        var run: @MainActor (ModelContext) throws -> String
        
        init(title: String, run: @escaping @MainActor (ModelContext) throws -> String) {
            self.title = title
            self.run = run
        }
    }
    
    struct SaveEvent: Hashable, Identifiable {
        let id: UUID = .init()
        let phase: String
        let timestamp: Date
        let inserted: [PersistentIdentifier]
        let updated: [PersistentIdentifier]
        let deleted: [PersistentIdentifier]
    }
    
    struct IncomingEdge: Hashable, Identifiable {
        var source, property: String
        var destination: String
        var deleteRule: Schema.Relationship.DeleteRule
        var isToOneRelationship: Bool
        var isOptional: Bool
        var isUnique: Bool
        
        var id: String {
            "\(source):\(property):\(destination)"
        }
        
        static func run(schema: Schema) -> [String: [IncomingEdge]] {
            var index = [String: [IncomingEdge]]()
            for source in schema.entities {
                for relationship in source.relationships {
                    let edge = IncomingEdge(
                        source: source.name,
                        property: relationship.name,
                        destination: relationship.destination,
                        deleteRule: relationship.deleteRule,
                        isToOneRelationship: relationship.isToOneRelationship,
                        isOptional: relationship.isOptional,
                        isUnique: relationship.isUnique
                    )
                    index[relationship.destination, default: []].append(edge)
                }
            }
            for key in index.keys {
                index[key]?.sort {
                    if $0.source != $1.source {
                        return $0.source < $1.source
                    } else {
                        return $0.property < $1.property
                    }
                }
            }
            return index
        }
    }
}
