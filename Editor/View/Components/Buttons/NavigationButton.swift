//
//  NavigationButton.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

enum NoRoute: Hashable {}

struct NavigationButton<Destination: View, Route: Hashable>: View {
    private var title: Text
    private var subtitle: Text?
    private var icon: Image?
    private var kind: Kind
    
    private enum Kind {
        case value(Route)
        case destination(() -> Destination)
    }
    
    init(
        _ title: String,
        _ subtitle: String? = nil,
        systemImage: String
    ) where Route == String, Destination == EmptyView {
        self.title = Text(LocalizedStringKey(title))
        self.subtitle = subtitle == nil ? nil : Text(LocalizedStringKey(subtitle!))
        self.icon = Image(systemName: systemImage)
        self.kind = .value(title)
    }
    
    init(
        _ titleKey: LocalizedStringKey,
        _ subtitleKey: LocalizedStringKey? = nil,
        systemImage: String
    ) where Route == String, Destination == EmptyView {
        self.title = Text(titleKey)
        self.subtitle = subtitleKey == nil ? nil : Text(subtitleKey!)
        self.icon = Image(systemName: systemImage)
        self.kind = .value(String(describing: title))
    }
    
    init(
        _ title: String,
        _ subtitle: String? = nil,
        systemImage: String,
        value: Route
    ) where Destination == EmptyView {
        self.title = Text(LocalizedStringKey(title))
        self.subtitle = subtitle == nil ? nil : Text(LocalizedStringKey(subtitle!))
        self.icon = Image(systemName: systemImage)
        self.kind = .value(value)
    }
    
    init(
        _ titleKey: LocalizedStringKey,
        _ subtitleKey: LocalizedStringKey? = nil,
        systemImage: String,
        value: Route
    ) where Destination == EmptyView {
        self.title = Text(titleKey)
        self.subtitle = subtitleKey == nil ? nil : Text(subtitleKey!)
        self.icon = Image(systemName: systemImage)
        self.kind = .value(value)
    }
    
    init(
        _ title: String,
        _ subtitle: String? = nil,
        systemImage: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) where Route == NoRoute {
        self.title = Text(LocalizedStringKey(title))
        self.subtitle = subtitle == nil ? nil : Text(LocalizedStringKey(subtitle!))
        self.icon = Image(systemName: systemImage)
        self.kind = .destination(destination)
    }
    
    init(
        _ titleKey: LocalizedStringKey,
        _ subtitleKey: LocalizedStringKey? = nil,
        systemImage: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) where Route == NoRoute {
        self.title = Text(titleKey)
        self.subtitle = subtitleKey == nil ? nil : Text(subtitleKey!)
        self.icon = Image(systemName: systemImage)
        self.kind = .destination(destination)
    }
    
    var body: some View {
        switch kind {
        case .value(let value):
            NavigationLink(value: value) { label }
        case .destination(let destination):
            NavigationLink { destination() } label: { label }
        }
    }
    
    @ViewBuilder private var label: some View {
        LabeledContent {
            subtitle.font(.caption)
        } label: {
            Label { title } icon: { icon }
        }
        .labeledContentStyle(ListLabeledContentStyle())
    }
}
