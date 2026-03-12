//
//  Observer.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreCore
import DataStoreRuntime
import DataStoreSupport
import Foundation
import Observation
import SwiftUI

#if swift(>=6.2)
import SwiftData
#else
@preconcurrency import SwiftData
#endif

@Observable final class Observer: DataStoreDelegate, DataStoreObservable {
    @MainActor var schema: Schema = .init()
    @MainActor var lastUpdated: Date? = .now
    @MainActor var changeTypes: Set<Schema.Entity> = []
    @MainActor var translations: [SQLPredicateTranslation] = []
    @MainActor var violations: [ConstraintViolation] = []
    @MainActor var saveEvents: [SchemaWorkbench.SaveEvent] = []
    @MainActor var maxTranslations: Int = 500
    @MainActor var maxSaveEvents: Int = 1000
    
    @MainActor private var nextTranslationContinuations:
    [Int?: [CheckedContinuation<SQLPredicateTranslation, Never>]] = [:]
    
    @MainActor func nextTranslation(matchHash: Int?) async -> SQLPredicateTranslation {
        if let existing = self.translations.last(where: { translation in
            guard let matchHash else { return true }
            if let predicateHash = translation.predicateHash {
                return predicateHash == matchHash
            }
            if let predicateDescription = translation.predicateDescription {
                return predicateDescription.hashValue == matchHash
            }
            return false
        }), existing.sql != nil ||
            existing.tree.path.contains(where: {
                $0.title == "Generated SQL"
            }) {
            return existing
        }
        return await withCheckedContinuation { continuation in
            nextTranslationContinuations[matchHash, default: []].append(continuation)
        }
    }
    
    @MainActor func resolveTranslation(_ translation: SQLPredicateTranslation) {
        if let index = self.translations.lastIndex(where: { $0.id == translation.id }) {
            translations[index] = translation
        } else {
            translations.append(translation)
        }
        let hasSQL = translation.sql != nil
        || translation.tree.path.contains(where: { $0.title == "Generated SQL" })
        if hasSQL {
            if let continuations = nextTranslationContinuations.removeValue(forKey: translation.predicateHash) {
                for continuation in continuations {
                    continuation.resume(returning: translation)
                }
            }
            if let continuations = nextTranslationContinuations.removeValue(forKey: nil) {
                for continuation in continuations {
                    continuation.resume(returning: translation)
                }
            }
        }
    }
    
    @MainActor var foreignKeyViolationsByTable: [String: [ConstraintViolation]] {
        Dictionary(grouping: violations.filter { $0.kind == .foreignKey }, by: \.table)
    }
    
    @MainActor var uniqueViolationsByTable: [String: [ConstraintViolation]] {
        Dictionary(grouping: violations.filter { $0.kind == .unique }, by: \.table)
    }
    
    @MainActor func maintenance() {}
    
    @MainActor func clear() {
        #if swift(>=6.2)
        saveEvents.removeAll()
        #endif
    }
    
    nonisolated var onTransactionFailure: @Sendable ([ConstraintViolation]) -> Void {
        { [weak self] constraints in
            Task { @MainActor in
                self?.violations.append(contentsOf: constraints)
            }
        }
    }
    
    nonisolated func storeWillSave() {
        Task { @MainActor in
            saveEvents.append(.init(
                phase: "will save",
                timestamp: .init(),
                inserted: [],
                updated: [],
                deleted: []
            ))
        }
    }
    
    nonisolated func storeDidSave(
        inserted: [PersistentIdentifier],
        updated: [PersistentIdentifier],
        deleted: [PersistentIdentifier]
    ) {
        Task { @MainActor in
            var changeTypes = Set<Schema.Entity>()
            for entityNames in [
                Set(inserted.map(\.entityName)),
                Set(updated.map(\.entityName)),
                Set(deleted.map(\.entityName))
            ] {
                for entityName in entityNames {
                    guard let entity = self.schema.entitiesByName[entityName] else {
                        continue
                    }
                    changeTypes.insert(entity)
                }
            }
            let lastUpdated = Date()
            self.lastUpdated = lastUpdated
            self.violations.removeAll()
            self.changeTypes = changeTypes
            saveEvents.append(.init(
                phase: "did save",
                timestamp: lastUpdated,
                inserted: inserted,
                updated: updated,
                deleted: deleted
            ))
        }
    }
    
    nonisolated required init(schema: Schema? = nil) {
        Task { @MainActor in
            self.schema = schema ?? .init()
        }
    }
    
    nonisolated static func sampleConstraintViolations(
        table: String,
        rows: [[String: any Sendable]]
    ) -> ([ConstraintViolation], [ConstraintViolation]) {
        var foreignKeyViolations = [ConstraintViolation]()
        var uniqueViolations = [ConstraintViolation]()
        let rowIDs = rows.compactMap { $0["rowid"] as? Int64 }
        let columns: [String] = {
            guard let row = rows.first else { return [] }
            return row.keys.filter { $0 != "rowid" && $0 != "pk" }
        }()
        if let rowID = rowIDs.randomElement() {
            foreignKeyViolations = [
                ConstraintViolation(
                    kind: .foreignKey,
                    table: table,
                    header: "\(table) -> parent",
                    rowid: rowID,
                    parentTable: "parent",
                    fkid: 1
                )
            ]
        }
        if let column = columns.randomElement() {
            uniqueViolations = [
                ConstraintViolation(
                    kind: .unique,
                    table: table,
                    header: "\(table).\(column)"
                )
            ]
        }
        return (foreignKeyViolations, uniqueViolations)
    }
}
