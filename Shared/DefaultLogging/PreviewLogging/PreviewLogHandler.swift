//
//  PreviewLogHandler.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Logging

public struct PreviewLogHandler: LogHandler {
    nonisolated public let key: String?
    nonisolated public let label: String
    /// Inherited from `LogHandler.logLevel`.
    nonisolated public var logLevel: Logger.Level = .trace
    /// Inherited from `LogHandler.metadata`.
    nonisolated public var metadata: Logger.Metadata = [:]
    
    nonisolated public init(
        label: String,
        forKey key: String? = nil
    ) {
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
        Task { @concurrent in
            let storedMetadata = self.metadata
            let combinedMetadata = metadata?.merging(storedMetadata, uniquingKeysWith: { $1 })
            ?? storedMetadata
            await PreviewLogView.Model.shared.append(
                level: level,
                message: "\(message)",
                metadata: combinedMetadata
            )
        }
    }
    
    /// Inherited from `LogHandler.subscript(metadataKey:)`.
    nonisolated public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }
}
