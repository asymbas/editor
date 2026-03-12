//
//  ContentHighlightModifier.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct HighlightModifier: ViewModifier {
    var isActive: Bool
    var color: Color = .red
    
    func body(content: Content) -> some View {
        content
            .background {
                if isActive { Rectangle().fill(color.opacity(0.15)) }
            }
            .overlay {
                if isActive {
                    Rectangle().strokeBorder(
                        color.secondary.opacity(0.25),
                        lineWidth: 1
                    )
                }
            }
    }
}

extension View {
    func highlight(isActive: Bool, color: Color = .red) -> some View {
        modifier(HighlightModifier(isActive: isActive))
    }
}
