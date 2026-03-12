//
//  Schema+SystemImageNameProviding.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

protocol SystemImageNameProviding {
    static var systemImage: String { get }
}

extension Entity: SystemImageNameProviding {
    static var systemImage: String { "cube.fill" }
}

extension SerialModel: SystemImageNameProviding {
    static var systemImage: String { "barcode" }
}

extension SchemaAttributeOptionModel: SystemImageNameProviding {
    static var systemImage: String { "slider.horizontal.3" }
}

extension SupportedScalarType: SystemImageNameProviding {
    static var systemImage: String { "number.square.fill" }
}

extension User: SystemImageNameProviding {
    static var systemImage: String { "person.fill" }
}

extension Profile: SystemImageNameProviding {
    static var systemImage: String { "person.crop.square.fill" }
}

extension Post: SystemImageNameProviding {
    static var systemImage: String { "doc.text.fill" }
}

extension Tag: SystemImageNameProviding {
    static var systemImage: String { "tag.fill" }
}

extension Cluster: SystemImageNameProviding {
    static var systemImage: String { "person.3.fill" }
}

extension Membership: SystemImageNameProviding {
    static var systemImage: String { "person.2.badge.gearshape.fill" }
}

extension Activity: SystemImageNameProviding {
    static var systemImage: String { "clock.arrow.circlepath" }
}
