//
//  AppearanceModifier.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct AppearanceModifier: ViewModifier {
    @AppStorage("appearance") private var appearance: Appearance = .automatic
    
    func body(content: Self.Content) -> some View {
        content.preferredColorScheme(appearance.colorScheme)
    }
}

extension View {
    func appearance() -> some View {
        modifier(AppearanceModifier())
    }
}
