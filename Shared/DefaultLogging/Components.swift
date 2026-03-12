//
//  Components.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension UserDefaults {
    nonisolated internal static var console: UserDefaults? {
        .init(suiteName: "Console")
    }
}

extension UserDefaults {
    @MainActor internal static let preview: UserDefaults? = {
        .init(suiteName: "Preview")
    }()
}
