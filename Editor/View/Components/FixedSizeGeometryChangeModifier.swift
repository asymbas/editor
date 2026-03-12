//
//  FixedSizeGeometryChangeModifier.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct FixedSizeGeometryChangeModifier: ViewModifier {
    /*nonisolated*/ var onChange: /*@Sendable*/ (CGFloat, CGFloat) -> Void
    
    func body(content: Content) -> some View {
        content
            .background {
                content
                    .fixedSize(horizontal: true, vertical: false)
                    .hidden()
                    .border(.clear)
                    .onGeometryChange(
                        for: CGFloat.self,
                        of: \.size.width
                    ) { oldValue, newValue in
                        onChange(oldValue, newValue)
                    }
            }
    }
}

extension View {
    func onFixedSizeGeometryChange(perform action: @escaping (CGFloat, CGFloat) -> Void) -> some View {
        modifier(FixedSizeGeometryChangeModifier(onChange: action))
    }
}
