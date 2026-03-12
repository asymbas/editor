//
//  Logger+UI.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Logging
import SwiftUI

extension Logger.Level: @retroactive Identifiable {
    nonisolated public var id: Self { self }
}

extension Logger.Level {
    nonisolated public var color: Color {
        switch self {
        case .trace: .gray
        case .debug: .green
        case .info: .blue
        case .notice: .blue
        case .warning: .yellow
        case .error: .red
        case .critical: .orange
        @unknown default: .white
        }
    }
}
