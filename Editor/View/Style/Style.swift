//
//  Style.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

extension Color {
    static var base: Color {
        #if os(iOS)
        .init(.systemBackground)
        #elseif os(macOS)
        .white
        #else
        .clear
        #endif
    }
    
    static var baseSecondary: Color {
        #if os(iOS)
        .init(.secondarySystemBackground)
        #elseif os(macOS)
        .white
        #else
        .clear
        #endif
    }
}

extension Color {
    static var random: Self {
        .init(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

extension ShapeStyle where Self == Color {
    static var random: Color { .random }
}

struct SectionGradualEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(alignment: .top) {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Rectangle().fill(.background)
                }
                .compositingGroup()
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(1.0), location: 0.0),
                            .init(color: .black.opacity(0.5), location: 0.8),
                            .init(color: .black.opacity(0.0), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
    }
}

extension View {
    func sectionGradualEffect() -> some View {
        modifier(SectionGradualEffect())
    }
}
