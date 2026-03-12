//
//  Helper.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftData

func makeID(_ prefix: (some PersistentModel).Type, _ components: [String]) -> String {
    let base = Schema.entityName(for: prefix)
        .lowercased()
        .split(whereSeparator: \.isWhitespace)
        .joined(separator: "-")
    let tail = components
        .map { $0.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: "-") }
        .joined(separator: "-")
    return tail.isEmpty ? base : "\(base)-\(tail)"
}

func makeID(_ prefix: (some PersistentModel).Type, _ components: String...) -> String {
    makeID(prefix, components)
}

private let consonants: [Character] = Array("bcdfghjklmnpqrstvwxyz")
private let vowels: [Character] = Array("aeiou")

func randomName(length: Int = 8) -> String {
    guard length > 0 else { return "" }
    var name = ""
    var useVowel = Bool.random()
    for _ in 0..<length {
        if useVowel {
            if let vowel = vowels.randomElement() {
                name.append(vowel)
            }
        } else {
            if let consonants = consonants.randomElement() {
                name.append(consonants)
            }
        }
        useVowel.toggle()
    }
    return name.capitalized
}

func makeDate(
    year: Int = .random(in: 2000...2025),
    month: Int = .random(in: 1...12),
    day: Int = .random(in: 1...31),
    hour: Int = .random(in: 0..<24),
    minute: Int = .random(in: 0..<60)
) -> Date {
    var components = DateComponents()
    components.calendar = Calendar(identifier: .gregorian)
    components.timeZone = TimeZone(secondsFromGMT: 0)
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    return components.date ?? .distantPast
}
