//
//  Other.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

nonisolated func sendable<T: Sendable>(cast value: Any) -> T? {
    value as? T
}

nonisolated func quote(_ identifier: String) -> String {
    "\"\(identifier.replacingOccurrences(of: "\"", with: "\"\""))\""
}

@discardableResult func copyToClipboard(_ string: String) -> Bool {
    #if canImport(AppKit)
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    return pasteboard.setString(string, forType: .string)
    #elseif canImport(UIKit)
    UIPasteboard.general.string = string
    return true
    #else
    return false
    #endif
}

func pasteFromClipboard() -> String? {
    #if canImport(AppKit)
    NSPasteboard.general.string(forType: .string)
    #elseif canImport(UIKit)
    UIPasteboard.general.string
    #else
    nil
    #endif
}
