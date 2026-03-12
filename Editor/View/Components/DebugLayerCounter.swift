//
//  DebugLayerCounter.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

@Observable final class LayerCounter {
    var value: Int = 0
    
    func next() -> Int {
        value += 1
        return value
    }
}

private struct LayerCounterKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: LayerCounter = .init()
}

extension EnvironmentValues {
    var layerCounter: LayerCounter {
        get { self[LayerCounterKey.self] }
        set { self[LayerCounterKey.self] = newValue }
    }
}

struct LayerCounterModifier: ViewModifier {
    @Environment(\.layerCounter) private var layerCounter
    @State private var count: Int?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if count == nil {
                    count = layerCounter.next()
                }
            }
            .overlay {
                Color.random.opacity(0.5).allowsHitTesting(false).overlay {
                    Text("\(count, default: "nil")")
                        .font(.title3)
                        .fontWeight(.heavy)
                }
            }
    }
}

extension View {
    func debugLayerCount() -> some View {
        modifier(LayerCounterModifier())
    }
}
