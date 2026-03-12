//
//  PredicateTreeView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

extension EnvironmentValues {
    @Entry fileprivate var scrollPosition: ScrollPosition = .init()
}

struct PredicateTreeView: View {
    @AppStorage("scroll-position") private var lastScrollPosition: Int?
    @State private var scrollPosition: ScrollPosition = .init(idType: Int.self, y: 0.0)
    @State private var scrollPhase: ScrollPhase = .idle
    private var nodes: [PredicateTreeNode]
    
    init(
        lastScrollPosition: Int? = nil,
        nodes: [PredicateTreeNode]
    ) {
        if let lastScrollPosition {
            self.scrollPosition = .init(id: lastScrollPosition)
        }
        self.nodes = nodes
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(
                    Array(tracedAncestryNodes.enumerated()),
                    id: \.offset
                ) { index, node in
                    PredicateTreeNodeView(model: node).id(index)
                }
            }
            .scrollTargetLayout()
            .padding()
            .background(.gray.opacity(0.1))
        }
        .scrollPosition($scrollPosition)
        .onScrollPhaseChange { _, newPhase in
            if !newPhase.isScrolling {
                if let scrollPosition = self.scrollPosition.viewID(type: Int.self) {
                    self.lastScrollPosition = scrollPosition
                }
            }
        }
        .onAppear {
            if let lastScrollPosition = self.lastScrollPosition {
                self.scrollPosition.scrollTo(id: lastScrollPosition)
            }
        }
    }
    
    private var tracedAncestryNodes: [PredicateTreeNode] {
        var stack: [(Int, Color)] = []
        return self.nodes.map { node in
            let ancestry = stack.filter { $0.0 < node.level }
            var node = node
            node.ancestry = ancestry
            if node.isComplete {
                stack.removeAll { $0.0 == node.level }
            } else {
                stack.append((node.level, node.color))
            }
            return node
        }
    }
}

struct PredicateTreeNodeView: View {
    @Environment(\.scrollPosition) private var scrollPosition
    @Environment(\.colorScheme) private var colorScheme
    @State private var isSelected: Bool = false
    @State var model: PredicateTreeNode
    
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(model.color.opacity(isSelected ? 0.5 : 0.1))
                .background(.ultraThinMaterial.quinary)
                .frame(maxWidth: .infinity)
                .padding(.leading, CGFloat(model.level * 12))
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    ForEach(model.ancestry, id: \.level) { ancestorLevel, ancestorColor in
                        Rectangle()
                            .fill(ancestorColor.opacity(0.2))
                            .frame(width: 4, height: geometry.size.height + 8)
                            .offset(x: CGFloat(ancestorLevel * 12))
                    }
                    Rectangle()
                        .fill(model.color)
                        .frame(width: 4, height: geometry.size.height)
                        .offset(x: CGFloat(model.level * 12))
                }
            }
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(model.isComplete ? "← EXIT" : "→ ENTER") \(model.expression)")
                        Spacer()
                        Group {
                            Text("\(model.key == nil ? "NULL" : "\(model.key!)")")
                            Text("\(model.level)").opacity(0.6)
                        }
                        .padding(.trailing, 5)
                    }
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(model.color)
                    Group {
                        if !model.content.isEmpty {
                            ForEach(Array(model.content.enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.caption)
                                    .foregroundStyle(model.isComplete ? Color.primary : Color.secondary)
                                    .opacity(1.0 - Double(index) * 0.25)
                            }
                        }
                        if !model.path.isEmpty {
                            HStack {
                                Text("Path: \(model.path.map { "\($0)" }.joined(separator: ", "))")
                            }
                            .font(.footnote)
                            .foregroundStyle(model.color)
                            .brightness(colorScheme == .light ? -0.3 : 0.3)
                        }
                    }
                    .bold()
                    .monospaced()
                    .padding(.leading, 4)
                }
            }
            .padding(.leading, CGFloat((model.level + 1) * 12))
            .padding(.vertical, 5)
        }
        .frame(minHeight: 40)
        .padding(.vertical, 4)
    }
}
