//
//  Schema+ShapeStyleProviding.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

protocol ShapeStyleProviding {
    @MainActor static var style: AnyShapeStyle { get }
}

extension Entity: ShapeStyleProviding {
    @MainActor static var style: AnyShapeStyle { AnyShapeStyle(Color.random) }
}

extension SerialModel: ShapeStyleProviding {
    @MainActor static var style: AnyShapeStyle { AnyShapeStyle(Color.gray) }
}

extension SchemaAttributeOptionModel: ShapeStyleProviding {
    @MainActor static var style: AnyShapeStyle { AnyShapeStyle(Color.brown) }
}

extension SupportedScalarType: ShapeStyleProviding {
    @MainActor static var style: AnyShapeStyle { AnyShapeStyle(Color.teal) }
}

extension SupportedOptionalScalarType: ShapeStyleProviding {
    @MainActor static var style: AnyShapeStyle { AnyShapeStyle(Color.teal.mix(with: .orange, by: 0.5, in: .device)) }
}

extension SupportedCollectionType: ShapeStyleProviding {
    @MainActor static var style: AnyShapeStyle { AnyShapeStyle(Color.mint) }
}

extension SupportedOptionalCollectionType: ShapeStyleProviding {
    @MainActor static var style: AnyShapeStyle { AnyShapeStyle(Color.mint.mix(with: .orange, by: 0.5, in: .device)) }
}

extension User: ShapeStyleProviding {
    @MainActor static var style: AnyShapeStyle { AnyShapeStyle(Color.accentColor) }
}

extension Profile: ShapeStyleProviding {
    @MainActor static var style: AnyShapeStyle { AnyShapeStyle(Color.blue) }
}

extension Post: ShapeStyleProviding {
    @MainActor static var style: AnyShapeStyle { AnyShapeStyle(Color.orange) }
}

extension Tag: ShapeStyleProviding {
    @MainActor static var style: AnyShapeStyle { AnyShapeStyle(Color.yellow) }
}

extension Cluster: ShapeStyleProviding {
    @MainActor static var style: AnyShapeStyle { AnyShapeStyle(Color.indigo) }
}

extension Membership: ShapeStyleProviding {
    @MainActor static var style: AnyShapeStyle { AnyShapeStyle(Color.purple) }
}

extension Activity: ShapeStyleProviding {
    @MainActor static var style: AnyShapeStyle { AnyShapeStyle(Color.pink) }
}
