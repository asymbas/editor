//
//  Configurator.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import SwiftData
import SwiftUI

private struct ConfiguratorKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: Configurator = .init()
}

extension EnvironmentValues {
    @MainActor var configurator: Configurator {
        get { self[ConfiguratorKey.self] }
        set { self[ConfiguratorKey.self] = newValue }
    }
}

@MainActor @Observable final class Configurator: Sendable {
    var library: Library?
    
    init() {
        if let id = UserDefaults.standard.string(forKey: "library") {
            change(to: .init(rawValue: id))
        }
    }
    
    func change(to configuration: consuming Configuration?) {
        guard let configuration else {
            self.library = nil
            UserDefaults.standard.removeObject(forKey: "library")
            return
        }
        self.library = .init(configuration: configuration)
        UserDefaults.standard.set(configuration.id, forKey: "library")
    }
}
