//
//  DefaultProvider.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftData
import SwiftUI

struct DefaultGraphLabel: GraphLabelProvider {
    nonisolated init() {}
    
    func title(for identifier: PersistentIdentifier) -> String {
        String(describing: identifier)
    }
    
    func subtitle(for identifier: PersistentIdentifier) -> String? {
        nil
    }
    
    func systemImage(for identifier: PersistentIdentifier) -> String? {
        "record.circle"
    }
}

struct DefaultGraphStyle: GraphStyleProvider {
    nonisolated init() {}
    
    func nodeFill(
        for identifier: PersistentIdentifier,
        selected: Bool,
        highlighted: Bool
    ) -> AnyShapeStyle {
        if selected { return AnyShapeStyle(.blue.opacity(0.85)) }
        if highlighted { return AnyShapeStyle(.teal.opacity(0.75)) }
        return AnyShapeStyle(.primary.opacity(0.12))
    }
    
    func nodeStroke(
        for identifier: PersistentIdentifier,
        selected: Bool,
        highlighted: Bool
    ) -> AnyShapeStyle {
        if selected { return AnyShapeStyle(.blue) }
        if highlighted { return AnyShapeStyle(.teal) }
        return AnyShapeStyle(.secondary)
    }
    
    func nodeRadius(for identifier: PersistentIdentifier) -> CGFloat {
        18
    }
    
    func edgeStroke(for edge: Graph.Edge, highlighted: Bool) -> Color {
        highlighted ? .teal : .secondary.opacity(0.75)
    }
    
    func edgeLineWidth(for edge: Graph.Edge, highlighted: Bool) -> CGFloat {
        highlighted ? 2.0 : 1.0
    }
    
    func edgeDash(for edge: Graph.Edge) -> [CGFloat]? {
        nil
    }
    
    func edgeLabelBackground(for edge: Graph.Edge) -> AnyShapeStyle {
        AnyShapeStyle(.thinMaterial)
    }
}

struct DefaultGraphInteraction: GraphInteractionProvider {
    nonisolated init() {}
    
    func didSelect(node identifier: PersistentIdentifier) -> Bool {
        return false
    }
    
    func contextMenu(for identifier: PersistentIdentifier) -> [GraphContextAction] {
        []
    }
}
