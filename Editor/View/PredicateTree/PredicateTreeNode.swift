//
//  PredicateTreeNode.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftData
import SwiftUI

struct PredicateTreeNode: Identifiable {
    var id: String = UUID().uuidString
    var index: Int
    var timestamp: Date = .now
    var ancestry: [(level: Int, color: Color)]
    var path: [PredicateExpressions.VariableID]
    var key: PredicateExpressions.VariableID?
    var expression: String
    var content: [String]
    var level: Int
    var isComplete: Bool
    var color: Color = .primary
    
    init(
        index: Int = 0,
        ancestry: [(Int, Color)] = [],
        path: [PredicateExpressions.VariableID] = [],
        key: PredicateExpressions.VariableID?,
        expression: String,
        content: [String],
        level: Int,
        isComplete: Bool
    ) {
        self.index = index
        self.ancestry = ancestry
        self.path = path
        self.key = key
        self.expression = expression
        self.content = content
        self.level = level
        self.isComplete = isComplete
        let id = composite + "_" + (isComplete ? "0" : "1")
        self.id = id
        self.color = mapExpressionToColor()
    }
    
    nonisolated private var composite: String {
        "\(expression)" + "_" + "\(level)" + "_" + "\(key == nil ? "NULL" : "\(key!)")"
    }
    
    nonisolated private func mapExpressionToColor() -> Color {
        switch expression.lowercased() {
        case "conjunction": .mint
        case "disjunction": .pink
        case "equal": .blue
        case "error": .red.mix(with: .black, by: 0.5)
        case "expressionevaluate": .teal
        case "notequal": .red
        case "keypath": .orange
        case "optionalflatmap": .brown
        case "predicateevaluate": .green
        case "sequencecontainswhere": .indigo
        case "success": .cyan
        case "value": .yellow
        case "variable": .purple
        default: .gray
        }
    }
}
