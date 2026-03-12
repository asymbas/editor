//
//  Constant.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

extension AppStorage where Value: RawRepresentable, Value.RawValue == String {
    init(wrappedValue: Value, _ key: ApplicationKey, store: UserDefaults? = nil) {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }
}

enum ApplicationKey: String {
    case tabViewMode
}

extension AppStorage where Value: RawRepresentable, Value.RawValue == String {
    init(wrappedValue: Value, _ key: PathKey, store: UserDefaults? = nil) {
        self.init(
            wrappedValue: wrappedValue,
            "path.\(key.rawValue)",
            store: store
        )
    }
}

extension AppStorage {
    init<Wrapped>(_ key: PathKey, store: UserDefaults? = nil)
    where Value == Wrapped?, Wrapped: RawRepresentable, Wrapped.RawValue == String {
        self.init("path.\(key.rawValue)", store: store)
    }
}

extension AppStorage where Value == String? {
    init(_ key: PathKey, store: UserDefaults? = nil) {
        self.init("path.\(key.rawValue)", store: store)
    }
}

enum PathKey: String {
    case route
    case tabContainer
}
