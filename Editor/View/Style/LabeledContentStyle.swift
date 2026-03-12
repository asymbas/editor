//
//  LabeledContentStyle.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct BasicListLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            configuration
                .label
            configuration
                .content
                .font(.caption)
                .foregroundStyle(.gray, .secondary)
        }
    }
}

struct ListLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        HStack(alignment: .center, spacing: 12) {
            configuration
                .label
                .labelStyle(.iconOnly)
                .imageScale(.large)
                .frame(width: 30)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading) {
                configuration
                    .label
                    .labelStyle(.titleOnly)
                    .font(.callout)
                configuration
                    .content
                    .lineLimit(2, reservesSpace: true)
                    .truncationMode(.tail)
                    .foregroundStyle(.secondary)
            }
        }
        .badgeProminence(.standard)
    }
}

struct KeyValueLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            configuration
                .label
            Spacer(minLength: 0)
            configuration
                .content
        }
    }
}

struct TitleLabeledContentStyle: LabeledContentStyle {
    var alignment: HorizontalAlignment = .leading
    var spacing: CGFloat?
    
    func makeBody(configuration: Self.Configuration) -> some View {
        VStack(alignment: alignment, spacing: spacing) {
            configuration
                .label
            configuration
                .content
        }
    }
}
