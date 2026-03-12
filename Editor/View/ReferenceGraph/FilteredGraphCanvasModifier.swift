//
//  FilteredGraphCanvasModifier.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

extension View where Self == GraphCanvas {
    func filteredGraphCanvas() -> some View {
        modifier(FilteredGraphCanvasModifier())
    }
}

private struct FilteredGraphCanvasModifier: ViewModifier {
    @Environment(Graph.self) private var view
    
    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if !view.searchText.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(view.nodes.values).filter { node in
                            let title = self.view.plugins.label.title(for: node.id)
                                .lowercased()
                            let subtitle = self.view.plugins.label.subtitle(for: node.id)?
                                .lowercased() ?? ""
                            let query = self.view.searchText
                                .lowercased()
                            return title.contains(query) || subtitle.contains(query)
                        }, id: \.id) { node in
                            Button {
                                withAnimation(.snappy) {
                                    view.selection = [node.id]
                                }
                            } label: {
                                Label(
                                    view.plugins.label.title(for: node.id),
                                    systemImage: view.plugins.label.systemImage(for: node.id)
                                    ?? "circle"
                                )
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(8)
                }
            }
        }
    }
}
