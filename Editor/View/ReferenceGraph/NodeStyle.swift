//
//  NodeStyle.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

enum EdgeConcernLevel: Sendable {
    case normal
    case warning
    case danger
}

enum EdgeLinePattern: Sendable {
    case solid
    case dotted
    case broken
}

enum NodeLabelPlacement: String, CaseIterable, Identifiable {
    case center
    case outerEdge
    case innerEdge
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .center: "Center"
        case .outerEdge: "Outer"
        case .innerEdge: "Inner"
        }
    }
}

struct CircularText: View {
    var text: String
    var radius: CGFloat
    var arcDegrees: Double
    var fontSize: CGFloat
    
    var body: some View {
        let truncated = truncateToFit(text)
        let stringElement = Array(truncated)
        Canvas { context, size in
            guard !stringElement.isEmpty else {
                return
            }
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let arc = self.arcDegrees * Double.pi / 180
            let step = arc / Double(max(1, stringElement.count))
            let start = -Double.pi / 2 - arc / 2 + step / 2
            for index in stringElement.indices {
                let theta = start + step * Double(index)
                var context = context
                context.translateBy(x: center.x, y: center.y)
                context.rotate(by: .radians(theta))
                context.translateBy(x: radius, y: 0)
                context.rotate(by: .radians(.pi / 2))
                context.draw(
                    Text(String(stringElement[index]))
                        .font(.system(size: fontSize, weight: .semibold, design: .monospaced)),
                    at: .zero, anchor: .center
                )
            }
        }
        .allowsHitTesting(false)
    }
    
    private func truncateToFit(_ string: String) -> String {
        let arc = self.arcDegrees * Double.pi / 180
        let arcLength = Double(radius) * arc
        let approximateCharacterWidth = Double(fontSize) * 0.62
        let maxCharacters = max(6, Int(arcLength / approximateCharacterWidth))
        if string.count <= maxCharacters { return string }
        if maxCharacters <= 1 { return "..."}
        return String(string.prefix(maxCharacters - 1)) + "..."
    }
}
