//
//  Schema+Type.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreRuntime
import SwiftData
import SwiftUI

extension EnvironmentValues {
    @Entry var schema: Schema = .init()
}

extension Schema {
    var types: [any PersistentModel.Type] {
        var types = [any PersistentModel.Type]()
        for entity in self.entities {
            if let type = entity.type {
                types.append(type)
            }
        }
        return types
    }
}
