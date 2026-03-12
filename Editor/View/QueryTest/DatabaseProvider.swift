//
//  DatabaseProvider.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import SwiftData

struct DatabaseProvider: Sendable {
    let schema: Schema
    let configuration: DatabaseConfiguration
    let modelContainer: ModelContainer
}
