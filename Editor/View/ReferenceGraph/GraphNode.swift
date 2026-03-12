//
//  GraphComponent.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftData
import SwiftUI

extension Graph {
    @MainActor @Observable final class Node: Identifiable, Sendable {
        nonisolated var id: PersistentIdentifier { persistentIdentifier }
        nonisolated let persistentIdentifier: PersistentIdentifier
        var position: CGPoint
        var velocity: CGPoint = .zero
        var degree: Int = 0
        var isFixed: Bool = false
        var isSelected: Bool = false
        var isHighlighted: Bool = false
        var systemImage: String?
        var title: String = ""
        var subtitle: String?
        var fill: AnyShapeStyle?
        var stroke: AnyShapeStyle?
        
        init(
            for persistentIdentifier: PersistentIdentifier,
            position: CGPoint,
            velocity: CGPoint = .zero,
            degree: Int = 0,
            isFixed: Bool = false
        ) {
            self.persistentIdentifier = persistentIdentifier
            self.position = position
            self.velocity = velocity
            self.degree = degree
            self.isFixed = isFixed
        }
    }
    
    struct Edge: Identifiable, Hashable, Sendable {
        let owner: PersistentIdentifier
        let property: String
        let target: PersistentIdentifier
        
        var id: Key {
            .init(owner: owner, property: property, target: target)
        }
        
        struct Key: Hashable, Sendable {
            let owner: PersistentIdentifier
            let property: String
            let target: PersistentIdentifier
        }
    }
}
