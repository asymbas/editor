//
//  RouteModifier.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftData
import SwiftUI

extension View {
    func restoreRouteOnTab<Tab: Hashable>(
        for requiredTab: Tab,
        selection tab: Binding<Tab>,
        decoders: [Route],
        clearsRouteWhenInactive: Bool = true,
        clearsRouteWhenPoppedToRoot: Bool = true
    ) -> some View {
        modifier(
            RestoreRouteOnTabModifier(
                tab: tab,
                requiredTab: requiredTab,
                decoders: decoders,
                clearsRouteWhenInactive: clearsRouteWhenInactive,
                clearsRouteWhenPoppedToRoot: clearsRouteWhenPoppedToRoot
            ).concat(RestoreRouteUsingAppStorageModifier())
        )
    }
    
    func restoreRouteOnTab<Tab: Hashable>(
        for requiredTab: Tab,
        selection tab: Binding<Tab>,
        in route: Binding<String?>,
        decoders: [Route],
        clearsRouteWhenInactive: Bool = true,
        clearsRouteWhenPoppedToRoot: Bool = true
    ) -> some View {
        modifier(
            RestoreRouteOnTabModifier(
                tab: tab,
                requiredTab: requiredTab,
                decoders: decoders,
                clearsRouteWhenInactive: clearsRouteWhenInactive,
                clearsRouteWhenPoppedToRoot: clearsRouteWhenPoppedToRoot
            ).concat(RestoreRouteUsingBindingModifier(route: route))
        )
    }
}

struct RestoreRouteOnTabModifier<Tab: Hashable>: ViewModifier {
    @Environment(\.router) private var router
    @Environment(\.route) private var route
    @Binding var tab: Tab
    var requiredTab: Tab
    var decoders: [Route]
    var clearsRouteWhenInactive: Bool = true
    var clearsRouteWhenPoppedToRoot: Bool = true
    
    func body(content: Content) -> some View {
        content
            .task(id: tab) {
                await Task.yield()
                await MainActor.run { restoreIfNeeded() }
            }
            .onChange(of: router.path.count) { _, count in
                guard clearsRouteWhenPoppedToRoot else { return }
                if count == 0 { route.wrappedValue = nil }
            }
    }
    
    @MainActor private func restoreIfNeeded() {
        guard tab == requiredTab, router.path.isEmpty else {
            if clearsRouteWhenInactive { route.wrappedValue = nil }
            return
        }
        guard let route = self.route.wrappedValue,
              let parts = Self.split(parsing: route) else {
            self.route.wrappedValue = nil
            return
        }
        var newPath = self.router.path
        var restored = false
        for decoder in decoders where decoder.key == parts.key {
            if decoder.restore(parts.value, &newPath) {
                restored = true
                break
            }
        }
        guard restored else {
            self.route.wrappedValue = nil
            return
        }
        self.router.path = newPath
    }
    
    static func split(parsing route: String) -> (key: String, value: String)? {
        guard let dot = route.firstIndex(of: ".") else { return nil }
        let key = String(route[..<dot])
        let value = String(route[route.index(after: dot)...])
        guard !key.isEmpty, !value.isEmpty else { return nil }
        return (key, value)
    }
}

extension EnvironmentValues {
    @Entry fileprivate var route: Binding<String?> = .constant(nil)
}

private struct RestoreRouteUsingAppStorageModifier: ViewModifier {
    @AppStorage(.route) private var route: String?
    
    func body(content: Content) -> some View {
        content.environment(\.route, $route)
    }
}

private struct RestoreRouteUsingBindingModifier: ViewModifier {
    @Binding var route: String?
    
    func body(content: Content) -> some View {
        content.environment(\.route, $route)
    }
}

@MainActor struct Route {
    var key: String
    var restore: (String, inout NavigationPath) -> Bool
    
    static func container<Container>(_ type: Container.Type) -> Self
    where Container: ContainerProtocol, Container.RawValue == String {
        .init(key: Container.key) { rawValue, path in
            guard let value = Container(rawValue: rawValue) else {
                return false
            }
            path.append(value)
            return true
        }
    }
}
