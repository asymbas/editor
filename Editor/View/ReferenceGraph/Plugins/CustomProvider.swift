//
//  CustomProvider.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreRuntime
import SwiftUI

#if swift(>=6.2)
import SwiftData
#else
@preconcurrency import SwiftData
#endif

struct CustomGraphLabel: GraphLabelProvider {
    private var schema: Schema
    @MainActor private var systemImageMap: [String: String]
    
    @MainActor init(schema: Schema) {
        self.schema = schema
        self.systemImageMap = {
            var dictionary = [String: String]()
            for entity in schema.entities {
                guard let type = Schema.type(for: entity.name),
                      let type = type as? any SystemImageNameProviding.Type else {
                    continue
                }
                dictionary[entity.name] = type.systemImage
            }
            return dictionary
        }()
    }
    
    func title(for identifier: PersistentIdentifier) -> String {
        identifier.entityName
    }
    
    func subtitle(for identifier: PersistentIdentifier) -> String? {
        String(identifier.primaryKey().prefix(5))
    }
    
    func systemImage(for identifier: PersistentIdentifier) -> String? {
        switch systemImageMap[identifier.entityName] {
        case let systemImage?: systemImage
        case nil: "record.circle"
        }
    }
}

struct CustomGraphStyle: GraphStyleProvider {
    private var schema: Schema
    @MainActor private var styleMap: [String: any ShapeStyle]
    
    @MainActor init(schema: Schema) {
        self.schema = schema
        self.styleMap = {
            var dictionary = [String: any ShapeStyle]()
            for entity in schema.entities {
                guard let type = Schema.type(for: entity.name),
                      let type = type as? any ShapeStyleProviding.Type else {
                    continue
                }
                dictionary[entity.name] = type.style
            }
            return dictionary
        }()
    }
    
    func nodeFill(
        for identifier: PersistentIdentifier,
        selected: Bool,
        highlighted: Bool
    ) -> AnyShapeStyle {
        if selected {
            switch styleMap[identifier.entityName] as? Style {
            case let value?: return AnyShapeStyle(value)
            case nil: return AnyShapeStyle(Color.accentColor.opacity(0.9))
            }
        }
        if highlighted {
            switch styleMap[identifier.entityName] as? Style {
            case _?: return AnyShapeStyle(.background)
            case nil: return AnyShapeStyle(.teal.opacity(0.8))
            }
        }
        return AnyShapeStyle(.secondary)
    }
    
    func nodeStroke(
        for identifier: PersistentIdentifier,
        selected: Bool,
        highlighted: Bool
    ) -> AnyShapeStyle {
        if selected {
            switch styleMap[identifier.entityName] as? Style {
            case let value?: return AnyShapeStyle(value.secondary)
            case nil: return AnyShapeStyle(Color.accentColor.opacity(0.9))
            }
        }
        if highlighted {
            switch styleMap[identifier.entityName] as? Style {
            case let value?: return AnyShapeStyle(value.secondary)
            case nil: return AnyShapeStyle(Color.accentColor.opacity(0.9))
            }
        }
        return AnyShapeStyle(Color.secondary /*.blue*/)
    }
    
    func nodeRadius(for identifier: PersistentIdentifier) -> CGFloat {
        18
    }
    
    func edgeStroke(for edge: Graph.Edge, highlighted: Bool) -> Color {
        switch concernLevel(for: edge) {
        case .danger: highlighted ? .red : .red.opacity(0.75)
        case .warning: highlighted ? .yellow : .yellow.opacity(0.75)
        case .normal: highlighted ? .teal : .secondary
        }
    }
    
    func edgeLineWidth(for edge: Graph.Edge, highlighted: Bool) -> CGFloat {
        switch concernLevel(for: edge) {
        case .danger: highlighted ? 2.6 : 2.0
        case .warning: highlighted ? 2.2 : 1.6
        case .normal: highlighted ? 3.0 : 2.0
        }
    }
    
    func edgeDash(for edge: Graph.Edge) -> [CGFloat]? {
        switch edgeLinePattern(for: edge) {
        case .solid: nil
        case .dotted: [1, 6]
        case .broken: [12, 10]
        }
    }
    
    func edgeLabelBackground(for edge: Graph.Edge) -> AnyShapeStyle {
        AnyShapeStyle(.thinMaterial)
    }
    
    private func concernLevel(for edge: Graph.Edge) -> EdgeConcernLevel {
        let property = edge.property.lowercased()
        if property.contains("error")
            || property.contains("broken")
            || property.contains("invalid") {
            return .danger
        }
        if property.contains("warn")
            || property.contains("deprecated")
            || property.contains("slow") {
            return .warning
        }
        return .normal
    }
    
    private func edgeLinePattern(for edge: Graph.Edge) -> EdgeLinePattern {
        let property = edge.property.lowercased()
        if property.contains("warning") || property.contains("deprecated") {
            return .broken
        }
        if property.contains("maybe") || property.contains("weak") {
            return .dotted
        }
        return .dotted
    }
}

struct CustomGraphInteraction: GraphInteractionProvider {
    var schema: Schema
    
    func didSelect(node identifier: PersistentIdentifier) -> Bool {
        false
    }
    
    func contextMenu(for identifier: PersistentIdentifier) -> [GraphContextAction] {
        []
    }
}
