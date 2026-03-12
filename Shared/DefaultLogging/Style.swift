//
//  Style.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Logging
import SwiftUI

struct MonospacedGroupBoxStyle: GroupBoxStyle {
    var alignment: HorizontalAlignment = .leading
    var spacing: CGFloat = 8.0
    
    func makeBody(configuration: Self.Configuration) -> some View {
        Group {
            VStack(alignment: alignment, spacing: spacing) {
                configuration
                    .label
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                configuration
                    .content
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .monospaced()
        }
        .safeAreaPadding()
        .background(Material.thin, in: .rect(cornerRadius: 8))
    }
}
