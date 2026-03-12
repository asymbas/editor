//
//  DateMetadata.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct DateMetadata: Codable {
    nonisolated var added: Date = .now
    nonisolated var updated: Date?
    nonisolated var opened: Date?
    nonisolated var created: Date?
    nonisolated var modified: Date?
}
