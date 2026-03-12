//
//  BannerModifier.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

public extension View {
    func banners(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil
    ) -> some View {
        self
            .banners(edge: .top, alignment: alignment, spacing: spacing)
            .banners(edge: .bottom, alignment: alignment, spacing: spacing)
    }
    
    func banners<BannerConfiguration: View>(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder configuration: @escaping (BannerCard) -> BannerConfiguration
    ) -> some View {
        self
            .banners(
                edge: .top,
                alignment: alignment,
                spacing: spacing,
                configuration: configuration
            )
            .banners(
                edge: .bottom,
                alignment: alignment,
                spacing: spacing,
                configuration: configuration
            )
    }
    
    func banners(
        edge: VerticalEdge,
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil
    ) -> some View {
        modifier(BannerModifier(
            edge: edge,
            alignment: alignment,
            spacing: spacing,
            configuration: {
                $0.transition(
                    .move(edge: edge == .top ? .top : .bottom)
                    .combined(with: .opacity)
                )
            }
        ))
    }
    
    func banners<BannerConfiguration: View>(
        edge: VerticalEdge,
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder configuration: @escaping (BannerCard) -> BannerConfiguration
    ) -> some View {
        modifier(BannerModifier(
            edge: edge,
            alignment: alignment,
            spacing: spacing,
            configuration: {
                configuration($0)
                    .transition(
                        .move(edge: edge == .top ? .top : .bottom)
                        .combined(with: .opacity)
                    )
            }
        ))
    }
}

private struct BannerModifier<BannerConfiguration: View>: ViewModifier {
    @State private var queue: BannerSystem = .shared
    internal var edge: VerticalEdge
    internal var alignment: HorizontalAlignment
    internal var spacing: CGFloat?
    internal let configuration: @MainActor (BannerCard) -> BannerConfiguration
    
    internal func body(content: Content) -> some View {
        content.safeAreaInset(edge: edge, alignment: alignment, spacing: spacing) {
            let banners = self.queue.banners(for: edge)
            if !banners.isEmpty {
                VStack(spacing: 10) {
                    ForEach(banners) { banner in
                        configuration(
                            BannerCard(
                                title: banner.title,
                                description: banner.description,
                                systemImage: banner.systemImage,
                                foreground: banner.foreground,
                                background: banner.background
                            ) {
                                queue.dismiss(banner.id)
                            }
                        )
                    }
                }.safeAreaPadding()
            }
        }
    }
}
