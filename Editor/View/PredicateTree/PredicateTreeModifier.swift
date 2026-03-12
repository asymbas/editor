//
//  PredicateTreeModifier.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreRuntime
import SwiftData
import SwiftUI

extension String {
    nonisolated static var showPredicateTree: Self {
        "show-predicate-tree"
    }
}

struct PredicateTreeButton: View {
    @AppStorage(.showPredicateTree)
    private var showPredicateTree: Bool = false
    
    var body: some View {
        Button("Predicate Tree") {
            withAnimation { self.showPredicateTree = true }
        }
    }
}

extension View {
    func predicateTreeOverlay() -> some View {
        modifier(PredicateTreeOverlayModifier())
    }
}

extension EnvironmentValues {
    @Entry fileprivate var scrollPosition: Binding<ScrollPosition> = .constant(.init(idType: UUID.self))
}

struct PredicateTreeOverlayModifier: ViewModifier {
    @Environment(Library.self) private var library
    @Environment(Observer.self) private var observer
    @AppStorage(.showPredicateTree) private var showPredicateTree: Bool = false
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if showPredicateTree {
                    VStack {
                        if !observer.translations.isEmpty {
                            ForEach(observer.translations.indices, id: \.self) { index in
                                let translation = self.observer.translations[index]
                                let nodes = translation.tree
                                Section {
                                    PredicateTreeView(nodes: (nodes).path.reduce(into: [PredicateTreeNode]()) { partialResult, nodes in
                                        partialResult.append(.init(
                                            key: nodes.key,
                                            expression: nodes.title,
                                            content: nodes.content,
                                            level: nodes.level,
                                            isComplete: nodes.isComplete
                                        ))
                                    })
                                } header: {
                                    Label {
                                        VStack(alignment: .leading) {
                                            Text("Predicate")
                                                .font(.callout.weight(.heavy))
                                            Text(nodes.id.uuidString)
                                                .font(.caption.weight(.medium))
                                                .monospaced()
                                                .id(translation.id)
                                        }
                                    } icon: {
                                        Image(systemName: "magnifyingglass")
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .safeAreaPadding()
                                }
                                .sectionActions {
                                    Button("Toggle") {
                                        showPredicateTree = false
                                    }
                                }
                            }
                        } else {
                            ContentUnavailableView(
                                "No Fetch Requests",
                                systemImage: "questionmark.circle",
                                description: Text("No fetch requests have been made yet.")
                            )
                        }
                    }
                    .modifier(ScrollPositionModifier {
                        ZStack {
                            Button("Close") {
                                self.showPredicateTree = false
                            }
                            HStack {
                                Spacer()
                                ScrollButton("Up", systemImage: "arrow.up") { scrollPosition in
                                    guard !observer.translations.isEmpty else { return }
                                    guard let currentIndex = currentTranslationIndex(for: scrollPosition) else {
                                        scrollToTranslation(at: 0, scrollPosition: &scrollPosition)
                                        return
                                    }
                                    scrollToTranslation(
                                        at: max(currentIndex - 1, 0),
                                        scrollPosition: &scrollPosition
                                    )
                                }
                                .contextMenu {
                                    ScrollButton("Top", systemImage: "") { scrollPosition in
                                        scrollPosition.scrollTo(edge: .top)
                                    }
                                }
                                ScrollButton("Down", systemImage: "arrow.down") { scrollPosition in
                                    guard !observer.translations.isEmpty else { return }
                                    guard let currentIndex = currentTranslationIndex(for: scrollPosition) else {
                                        scrollToTranslation(at: 0, scrollPosition: &scrollPosition)
                                        return
                                    }
                                    scrollToTranslation(
                                        at: min(currentIndex + 1, observer.translations.count - 1),
                                        scrollPosition: &scrollPosition
                                    )
                                }
                                .contextMenu {
                                    ScrollButton("Down", systemImage: "") { scrollPosition in
                                        scrollPosition.scrollTo(edge: .bottom)
                                    }
                                }
                            }
                            .labelStyle(.iconOnly)
                        }
                        .fontWeight(.semibold)
                        .buttonStyle(.borderedProminent)
                        .safeAreaPadding()
                    })
                    .background(
                        .ultraThinMaterial.quinary,
                        ignoresSafeAreaEdges: .all
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.9, anchor: .bottom)),
                        removal: .scale.combined(with: .opacity)
                    ))
                    .transition(.scale)
                }
            }
            .animation(
                .interactiveSpring(duration: 0.2, extraBounce: 0.1, blendDuration: 0.5),
                value: showPredicateTree
            )
    }
    
    private func currentTranslationIndex(for scrollPosition: ScrollPosition) -> Int? {
        guard let id = scrollPosition.viewID(type: UUID.self) else { return nil }
        return observer.translations.firstIndex { $0.id == id }
    }
    
    private func scrollToTranslation(at index: Int, scrollPosition: inout ScrollPosition) {
        guard observer.translations.indices.contains(index) else { return }
        withAnimation {
            scrollPosition.scrollTo(id: observer.translations[index].id, anchor: .top)
        }
    }
    
    struct ScrollPositionModifier<SafeAreaInset: View>: ViewModifier {
        @State private var scrollPosition: ScrollPosition = .init(idType: UUID.self)
        @ViewBuilder var safeAreaInset: SafeAreaInset
        
        func body(content: Self.Content) -> some View {
            ScrollView {
                content
            }
            .safeAreaInset(edge: .bottom) {
                safeAreaInset
            }
            .scrollPosition($scrollPosition)
            .environment(\.scrollPosition, $scrollPosition)
            .defaultScrollAnchor(.bottom, for: .alignment)
            .defaultScrollAnchor(.bottom, for: .initialOffset)
            .defaultScrollAnchor(.bottom, for: .sizeChanges)
        }
    }
    
    struct ScrollButton: View {
        @Environment(\.scrollPosition) private var scrollPosition
        var title: Text
        var icon: Image
        var action: (inout ScrollPosition) -> Void
        
        init(
            _ title: String,
            systemImage: String,
            action: @escaping (inout ScrollPosition) -> Void
        ) {
            self.title = Text(title)
            self.icon = Image(systemName: systemImage)
            self.action = action
        }
        
        var body: some View {
            Button {
                action(&scrollPosition.wrappedValue)
            } label: {
                Label(title: { title }, icon: { icon })
            }
        }
    }
}
