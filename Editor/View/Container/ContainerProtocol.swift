//
//  ContainerProtocol.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

protocol ContainerProtocol: CaseIterable, Hashable, Identifiable, RawRepresentable {
    associatedtype Body: View
    @MainActor @ViewBuilder var route: Body { get }
    @MainActor var title: String { get }
    @MainActor var details: String { get }
    @MainActor var systemImage: String { get }
    @MainActor static var key: String { get }
}

extension ContainerProtocol {
    var id: Self { self }
}

struct ContainerView<Container: ContainerProtocol>: View {
    var container: Container
    
    var body: some View {
        container.route
    }
}

struct ContainerNavigationModifier<Container: ContainerProtocol>: ViewModifier {
    @AppStorage(.route) private var route: String?
    var container: Container.Type
    
    func body(content: Content) -> some View {
        content.navigationDestination(for: Container.self) { container in
            ContainerView(container: container)
                .navigationTitle(container.title)
                .onAppear { self.route = "\(Container.key).\(container.rawValue)" }
        }
    }
}

extension View {
    func link<C: ContainerProtocol>(to container: C.Type) -> some View {
        modifier(ContainerNavigationModifier(container: C.self))
    }
}

extension NavigationButton where Destination == EmptyView, Route: ContainerProtocol {
    init(container: Route) where Route: ContainerProtocol {
        self.init(
            container.title,
            container.details,
            systemImage: container.systemImage,
            value: container
        )
    }
}


