//
//  Constants.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

enum Key: String {
    case minimumLogLevel
    case filterLogLevel
    case filterText
    case filterLabels
    case filterSource
    case filterFile
    case filterFunction
    case useDetailedLogging
    case lastScrollPosition
    case inlineLoggerMetadata
    case isEnabled
}

extension AppStorage where Value == Bool {
    init(wrappedValue: Value = false, _ key: Key, store: UserDefaults? = nil) {
        self.init(wrappedValue: wrappedValue, "logging.\(key.rawValue)", store: store)
    }
}

extension AppStorage where Value == Bool? {
    init(_ key: Key, store: UserDefaults? = nil) {
        self.init("logging.\(key.rawValue)", store: store)
    }
}

extension AppStorage where Value: RawRepresentable, Value.RawValue == Int {
    nonisolated internal init(wrappedValue: Value, _ key: Key, store: UserDefaults? = nil) {
        self.init(wrappedValue: wrappedValue, "logging.\(key.rawValue)", store: store)
    }
}

extension AppStorage {
    init<Wrapped>(_ key: Key, store: UserDefaults? = nil)
    where Value == Wrapped?, Wrapped: RawRepresentable, Wrapped.RawValue == Int {
        self.init("logging.\(key.rawValue)", store: store)
    }
}

extension AppStorage where Value == Int {
    init(wrappedValue: Value = .init(), _ key: Key, store: UserDefaults? = nil) {
        self.init(wrappedValue: wrappedValue, "logging.\(key.rawValue)", store: store)
    }
}

extension AppStorage where Value == Int? {
    init(_ key: Key, store: UserDefaults? = nil) {
        self.init("logging.\(key.rawValue)", store: store)
    }
}

extension AppStorage where Value: RawRepresentable, Value.RawValue == String {
    nonisolated internal init(wrappedValue: Value, _ key: Key, store: UserDefaults? = nil) {
        self.init(wrappedValue: wrappedValue, "logging.\(key.rawValue)", store: store)
    }
}

extension AppStorage {
    init<Wrapped>(_ key: Key, store: UserDefaults? = nil)
    where Value == Wrapped?, Wrapped: RawRepresentable, Wrapped.RawValue == String {
        self.init("logging.\(key.rawValue)", store: store)
    }
}

extension AppStorage where Value == String {
    init(wrappedValue: Value = .init(), _ key: Key, store: UserDefaults? = nil) {
        self.init(wrappedValue: wrappedValue, "logging.\(key.rawValue)", store: store)
    }
}

extension AppStorage where Value == String? {
    init(_ key: Key, store: UserDefaults? = nil) {
        self.init("logging.\(key.rawValue)", store: store)
    }
}
