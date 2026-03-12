//
//  Router.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

extension EnvironmentValues {
    var router: Router {
        get { self[RouterKey.self] }
        set { self[RouterKey.self] = newValue }
    }
}

private struct RouterKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: Router = .init()
}

@MainActor @Observable final class Router: Sendable {
    var path: NavigationPath = .init()
}
