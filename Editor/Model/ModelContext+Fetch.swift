//
//  ModelContext+Fetch.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import Foundation
import SwiftData

extension ModelContext {
    func preloadedFetch<T>(
        all type: T.Type,
        limit: Int? = nil,
        offset: Int? = nil,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> [T] where T: PersistentModel {
        var descriptor = FetchDescriptor<T>()
        if let limit { descriptor.fetchLimit = limit }
        if let offset { descriptor.fetchOffset = offset }
        return try await preloadedFetch(descriptor, isolation: isolation)
    }
}

extension ModelContext {
    // FIXME: Does not work with non concrete types.
    func fetch<T>(
        type: T.Type,
        makeDescriptor: (inout FetchDescriptor<T>) -> Void
    ) throws -> [T] where T: PersistentModel {
        var descriptor = FetchDescriptor<T>()
        makeDescriptor(&descriptor)
        return try fetch(descriptor)
    }
    
    func fetch<T>(
        all type: T.Type,
        limit: Int? = nil,
        offset: Int? = nil
    ) throws -> [T] where T: PersistentModel {
        var descriptor = FetchDescriptor<T>()
        if let limit { descriptor.fetchLimit = limit }
        if let offset { descriptor.fetchOffset = offset }
        return try fetch(descriptor)
    }
    
    func fetchIdentifiers<T>(
        all type: T.Type,
        limit: Int? = nil,
        offset: Int? = nil
    ) throws -> [PersistentIdentifier] where T: PersistentModel {
        var descriptor = FetchDescriptor<T>()
        if let limit { descriptor.fetchLimit = limit }
        if let offset { descriptor.fetchOffset = offset }
        return try fetchIdentifiers(descriptor)
    }
    
    func fetchCount<T>(
        all type: T.Type,
        limit: Int? = nil,
        offset: Int? = nil
    ) throws -> Int where T: PersistentModel {
        var descriptor = FetchDescriptor<T>()
        if let limit { descriptor.fetchLimit = limit }
        if let offset { descriptor.fetchOffset = offset }
        return try fetchCount(descriptor)
    }
    
    func fetch<T>(for id: T.ID, as type: T.Type) -> T?
    where T: Identifiable & PersistentModel, T.ID == String {
        var descriptor = FetchDescriptor(predicate: #Predicate<T> { $0.id == id })
        descriptor.fetchLimit = 1
        return try? fetch(descriptor).first
    }
    
    func fetch<T>(for persistentModelID: PersistentIdentifier, as type: T.Type) -> T?
    where T: PersistentModel {
        var descriptor = FetchDescriptor(predicate: #Predicate<T> {
            $0.persistentModelID == persistentModelID
        })
        descriptor.fetchLimit = 1
        return try? fetch(descriptor).first
    }
}
