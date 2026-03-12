//
//  Log.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Logging

public struct Log: Equatable, Hashable, Identifiable, Sendable {
    nonisolated public let id: UUID = .init()
    nonisolated public let date: Date
    nonisolated public let level: Logging.Logger.Level
    nonisolated public let message: Logging.Logger.Message
    nonisolated public let metadata: Logging.Logger.Metadata?
    nonisolated public let label: String
    nonisolated public let source: String
    nonisolated public let file: String
    nonisolated public let function: String
    nonisolated public let line: UInt
    nonisolated public var hasViewed: Bool = false
    
    nonisolated public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
        && lhs.date == rhs.date
        && lhs.level == rhs.level
        && lhs.message == rhs.message
        && lhs.metadata == rhs.metadata
        && lhs.label == rhs.label
        && lhs.source == rhs.source
        && lhs.file == rhs.file
        && lhs.function == rhs.function
        && lhs.line == rhs.line
        && lhs.hasViewed == rhs.hasViewed
    }
    
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(date)
        hasher.combine(level)
        hasher.combine(message.description)
        hasher.combine(metadata?.description)
        hasher.combine(label)
        hasher.combine(source)
        hasher.combine(file)
        hasher.combine(function)
        hasher.combine(UInt64(line))
        hasher.combine(hasViewed)
    }
}
