//
//  Badge.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftData
import SwiftUI

struct BadgeContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.bar, in: Capsule())
            .fixedSize()
    }
}

extension View {
    func badgeContainer() -> some View {
        modifier(BadgeContainerModifier())
    }
}

struct AlertBadgeContainerModifier: ViewModifier {
    var color: Color = .red
    
    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(in: Capsule())
            .backgroundStyle(color)
            .clipShape(Capsule())
    }
}

extension View where Self == Text {
    func alertBadgeContainer(color: Color = .red) -> some View {
        modifier(AlertBadgeContainerModifier(color: color))
    }
}

extension View {
    @ViewBuilder func isIncomplete(_ isIncomplete: Bool) -> some View {
        if isIncomplete {
            overlay(alignment: .topTrailing) {
                Text("Incomplete")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .padding(.trailing, 4)
                    .allowsHitTesting(false)
            }
        } else {
            self
        }
    }
}
