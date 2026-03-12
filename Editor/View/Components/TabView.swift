//
//  TabView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Logging
import SwiftUI

#if canImport(Shared)
import Shared
#endif

extension ContainerValues {
    @Entry fileprivate var selection: TabSelection?
    @Entry fileprivate var badge: String?
}

extension View {
    func tab<T: Hashable>(_ title: String, systemImage: String, value: T) -> some View {
        containerValue(\.selection, .init(value: value, title: title, systemImage: systemImage))
    }
    
    func tabBadge(_ text: String?) -> some View {
        containerValue(\.badge, text)
    }
    
    func tabBadge(_ count: Int) -> some View {
        containerValue(\.badge, count > 0 ? "\(count)" : nil)
    }
}

fileprivate struct TabSelection: Hashable {
    var value: AnyHashable
    var title: String
    var systemImage: String
}

struct CustomTabView<Content: View, Selection: Hashable>: View {
    @State private var height: CGFloat = 0
    @State private var mountedTabs: Set<Selection>
    @Binding private var selection: Selection
    @ViewBuilder private let content: Content
    
    init(selection: Binding<Selection>, @ViewBuilder content: () -> Content) {
        self.content = content()
        _selection = selection
        _mountedTabs = State(initialValue: [selection.wrappedValue])
    }
    
    var body: some View {
        switch false {
        case true: floating.onChange(of: selection) { mountedTabs.insert($1) }
        case false: edge.onChange(of: selection) { mountedTabs.insert($1) }
        }
    }
    
    @ViewBuilder var floating: some View {
        let barHeight: CGFloat = 60
        let barBottomGap: CGFloat = 10
        let reservedBottom = barHeight + barBottomGap
        ZStack(alignment: .bottom) {
            ZStack {
                ForEach(subviews: content) { subview in
                    if let tab = subview.containerValues.selection,
                       let value = tab.value as? Selection,
                       mountedTabs.contains(value) {
                        VStack {
                            subview
                                .debugLayerCount()
                                .modifier(SafeAreaContainer {
                                    TabComponent(selection: $selection, content: content)
                                        .frame(height: barHeight)
                                        .padding(.horizontal)
                                        .background(.bar)
                                        .clipShape(.rect)
                                        .padding(.horizontal)
                                        .padding(.bottom, barBottomGap)
                                        .zIndex(100)
                                        .opacity(0.5)
                                })
                                .border(.purple, width: 3)
                                .safeAreaPadding(.bottom, 100)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.background)
                        .opacity(value == selection ? 1 : 0)
                        .allowsHitTesting(value == selection)
                        .zIndex(value == selection ? 1 : 0)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear
                        .frame(height: reservedBottom)
                        .allowsHitTesting(false)
                        .border(.orange)
                }
            }
        }
    }
    
    @ViewBuilder var edge: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Overlap tabs to prevent resetting state.
                ZStack {
                    ForEach(subviews: content) { subview in
                        if let tab = subview.containerValues.selection,
                           let value = tab.value as? Selection,
                           mountedTabs.contains(value) {
                            subview
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(.background)
                                .opacity(value == selection ? 1 : 0)
                                .allowsHitTesting(value == selection)
                                .zIndex(value == selection ? 1 : 0)
                        }
                    }
                }
                VStack {
                    Divider()
                    TabComponent(selection: $selection, content: content)
                }
                .frame(height: 60)
                .ignoresSafeArea(.all, edges: .bottom)
                .clipShape(.rect)
                .padding(.horizontal)
                .background(.bar)
                #if false
                .overlay(alignment: .bottom) {
                    VStack {
                        Divider().hidden()
                        TabBar(selection: $tab)
                    }
                    .onGeometryChange(for: CGFloat.self, of: \.size.height) { _, newValue in
                        self.height = newValue
                    }
                    .frame(height: 60)
                    .background(in: .containerRelative)
                    .backgroundStyle(.bar)
                    .shadow(color: .gray, radius: 25.0, x: 0, y: 50)
                    .padding(.horizontal)
                    .ignoresSafeArea()
                    .padding(.bottom, 10)
                }
                #endif
            }
        }
    }
    
    struct SafeAreaContainer<Overlay: View>: ViewModifier {
        @ViewBuilder var bar: Overlay
        
        func body(content: Self.Content) -> some View {
            ForEach(subviews: content) { subview in
                ForEach(subviews: subview) { subview in
                    ZStack {
                        subview
                            .border(.random)
                    }
                    .safeAreaInset(edge: .bottom) {
                        VStack {
                            Spacer()
                            bar
                        }
                    }
                }
            }
        }
    }
    
    struct TabComponent: View {
        @Binding var selection: Selection
        var content: Content
        
        var body: some View {
            HStack(spacing: 0) {
                ForEach(subviews: content) { subview in
                    if let tab = subview.containerValues.selection,
                       let value = tab.value as? Selection {
                        Button {
                            withAnimation(.spring) {
                                self.selection = value
                            }
                        } label: {
                            VStack(spacing: 6) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: tab.systemImage)
                                        .font(.system(size: 18, weight: .semibold))
                                    if let badge = subview.containerValues.badge {
                                        Text(badge)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.red)
                                            .foregroundStyle(.white)
                                            .clipShape(Capsule())
                                            .offset(x: 10, y: -10)
                                    }
                                }
                                Text(tab.title)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(selection == value ? .primary : .secondary)
                        .padding(.vertical, 10)
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }
}
