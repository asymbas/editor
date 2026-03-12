//
//  GraphPluginProtocol.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftData
import SwiftUI

protocol GraphLabelProvider: Sendable {
    nonisolated func title(for identifier: PersistentIdentifier) -> String
    nonisolated func subtitle(for identifier: PersistentIdentifier) -> String?
    nonisolated func systemImage(for identifier: PersistentIdentifier) -> String?
}

protocol GraphStyleProvider: Sendable {
    associatedtype Style: ShapeStyle
    nonisolated func nodeFill(
        for identifier: PersistentIdentifier,
        selected: Bool,
        highlighted: Bool
    ) -> Style
    nonisolated func nodeStroke(
        for identifier: PersistentIdentifier,
        selected: Bool,
        highlighted: Bool
    ) -> Style
    nonisolated func nodeRadius(for identifier: PersistentIdentifier) -> CGFloat
    nonisolated func edgeStroke(for edge: Graph.Edge, highlighted: Bool) -> Color
    nonisolated func edgeLineWidth(for edge: Graph.Edge, highlighted: Bool) -> CGFloat
    nonisolated func edgeDash(for edge: Graph.Edge) -> [CGFloat]?
    nonisolated func edgeLabelBackground(for edge: Graph.Edge) -> AnyShapeStyle
}

protocol GraphInteractionProvider: Sendable {
    nonisolated func didSelect(node identifier: PersistentIdentifier) -> Bool
    nonisolated func contextMenu(for identifier: PersistentIdentifier) -> [GraphContextAction]
}
