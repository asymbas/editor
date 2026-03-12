//
//  ConsoleLogHandler.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Logging

public struct ConsoleLogHandler: LogHandler {
    nonisolated private let console: Console
    nonisolated public let key: String?
    nonisolated public let label: String
    /// Inherited from `LogHandler.logLevel`.
    nonisolated public var logLevel: Logger.Level = .trace
    /// Inherited from `LogHandler.metadata`.
    nonisolated public var metadata: Logger.Metadata = [:]
    
    nonisolated public init(
        label: String,
        forKey key: String? = nil,
        console: Console = .shared
    ) {
        self.console = console
        self.key = key
        self.label = label
    }
    
    /// Inherited from `LogHandler.log(level:message:metadata:source:file:function:line:)`.
    nonisolated public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let storedMetadata = self.metadata
        Task { @ConsoleActor in
            let combinedMetadata = metadata?.merging(storedMetadata, uniquingKeysWith: { $1 })
            ?? storedMetadata
            if let key = self.key, combinedMetadata[key] == nil {
                return
            }
            await console.output(
                date: .now,
                level: level,
                message: message,
                metadata: combinedMetadata,
                label: label,
                source: source,
                file: file,
                function: function,
                line: line
            )
        }
    }
    
    /// Inherited from `LogHandler.subscript(metadataKey:)`.
    nonisolated public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }
}
