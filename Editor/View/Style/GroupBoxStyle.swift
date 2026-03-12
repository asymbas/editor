//
//  GroupBoxStyle.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct BasicGroupBoxStyle: GroupBoxStyle {
    var alignment: HorizontalAlignment = .leading
    var spacing: CGFloat = 8.0
    
    func makeBody(configuration: Self.Configuration) -> some View {
        VStack(alignment: alignment, spacing: spacing) {
            configuration
                .label
                .font(.headline)
            configuration
                .content
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
