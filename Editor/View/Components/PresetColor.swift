//
//  PresetColor.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

enum PresetColor: String, CaseIterable, Hashable, Identifiable {
    case black
    case blue
    case brown
    case clear
    case cyan
    case gray
    case green
    case indigo
    case mint
    case orange
    case pink
    case purple
    case red
    case teal
    case white
    case yellow
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .black: .black
        case .blue: .blue
        case .brown: .brown
        case .clear: .clear
        case .cyan: .cyan
        case .gray: .gray
        case .green: .green
        case .indigo: .indigo
        case .mint: .mint
        case .orange: .orange
        case .pink: .pink
        case .purple: .purple
        case .red: .red
        case .teal: .teal
        case .white: .white
        case .yellow: .yellow
        }
    }
}

struct AccentColorPicker: View {
    @AppStorage("accent-color") private var accentColor: PresetColor?
    
    var body: some View {
        Picker("Accent Color", selection: $accentColor) {
            Label("System", systemImage: "circle.fill")
                .tag(nil as PresetColor?)
            ForEach(PresetColor.allCases) { accentColor in
                Label {
                    Text(accentColor.rawValue)
                } icon: {
                    Circle()
                        .fill(accentColor.color)
                        .frame(width: 10)
                }
                .tag(Optional(accentColor), includeOptional: true)
            }
        }
    }
}

struct AccentColorModifier: ViewModifier {
    @AppStorage("accent-color") private var accentColor: PresetColor?
    
    func body(content: Content) -> some View {
        content.tint(accentColor?.color ?? .accentColor)
    }
}

extension View {
    func accentColor() -> some View {
        modifier(AccentColorModifier())
    }
}
