//
//  ModelFetchListBuilder.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

@resultBuilder enum ModelFetchListBuilder {
    static func buildExpression(_ expression: DatabaseFetch) -> [DatabaseFetch] {
        [expression]
    }
    
    static func buildExpression(_ expression: [DatabaseFetch]) -> [DatabaseFetch] {
        expression
    }
    
    static func buildBlock(_ components: [DatabaseFetch]...) -> [DatabaseFetch] {
        components.flatMap(\.self)
    }
    
    static func buildOptional(_ component: [DatabaseFetch]?) -> [DatabaseFetch] {
        component ?? []
    }
    
    static func buildEither(first component: [DatabaseFetch]) -> [DatabaseFetch] {
        component
    }
    
    static func buildEither(second component: [DatabaseFetch]) -> [DatabaseFetch] {
        component
    }
    
    static func buildArray(_ components: [[DatabaseFetch]]) -> [DatabaseFetch] {
        components.flatMap(\.self)
    }
    
    static func buildLimitedAvailability(_ component: [DatabaseFetch]) -> [DatabaseFetch] {
        component
    }
}
