//
//  Schema+DefaultInitializer.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol DefaultInitializer {
    init()
}

extension SupportedScalarType: DefaultInitializer {
    convenience init() {
        self.init(id: UUID().uuidString)
    }
}

extension SupportedOptionalScalarType: DefaultInitializer {
    convenience init() {
        self.init(id: UUID().uuidString)
    }
}

extension SupportedCollectionType: DefaultInitializer {
    convenience init() {
        self.init(id: UUID().uuidString)
    }
}

extension SupportedOptionalCollectionType: DefaultInitializer {
    convenience init() {
        self.init(id: UUID().uuidString)
    }
}
