//
//  BannerCard.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

public struct BannerCard: View {
    internal var title: String
    internal var description: String?
    internal var systemImage: String?
    internal var foreground: Color?
    internal var background: Color?
    internal var onDismiss: () -> Void
    internal var customView: (@MainActor () -> AnyView)?
    
    public var body: some View {
        HStack(spacing: 10) {
            if let systemImage = self.systemImage {
                Image(systemName: systemImage)
                    .imageScale(.large)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .bold(description != nil || customView != nil)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let description = self.description {
                    Text(description)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle((foreground ?? .primary).opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let customView = self.customView {
                    customView()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .foregroundStyle(foreground ?? .primary)
        .background(layer)
        .contentShape(.rect)
        .onTapGesture(perform: onDismiss)
    }
    
    @ViewBuilder private var layer: some View {
        Group {
            if let background = self.background {
                Rectangle().fill(.ultraThinMaterial).background(background)
            } else {
                Rectangle().fill(.ultraThinMaterial)
            }
        }.clipShape(.rect(cornerRadius: 20))
    }
}
