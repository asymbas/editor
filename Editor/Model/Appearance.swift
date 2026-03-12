//
//  Appearance.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

enum Appearance: String, CaseIterable {
    case automatic
    case light
    case dark
    
    init(from colorScheme: ColorScheme?) {
        switch colorScheme {
        case .light: self = .light
        case .dark: self = .dark
        default: self = .automatic
        }
    }
    
    var cycle: Self {
        switch self {
        case .automatic: .light
        case .light: .dark
        case .dark: .automatic
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
