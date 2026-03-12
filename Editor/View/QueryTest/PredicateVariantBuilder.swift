//
//  PredicateVariantBuilder.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftData

@resultBuilder enum PredicateVariantBuilder<Model: PersistentModel> {
    static func buildExpression(_ expression: PredicateVariant<Model>) -> PredicateVariant<Model> {
        expression
    }
    
    static func buildBlock(_ components: PredicateVariant<Model>...) -> [PredicateVariant<Model>] {
        components
    }
    
    static func buildArray(_ components: [[PredicateVariant<Model>]]) -> [PredicateVariant<Model>] {
        components.flatMap(\.self)
    }
    
    static func buildOptional(_ component: [PredicateVariant<Model>]?) -> [PredicateVariant<Model>] {
        component ?? []
    }
    
    static func buildEither(first: [PredicateVariant<Model>]) -> [PredicateVariant<Model>] {
        first
    }
    
    static func buildEither(second: [PredicateVariant<Model>]) -> [PredicateVariant<Model>] {
        second
    }
}
