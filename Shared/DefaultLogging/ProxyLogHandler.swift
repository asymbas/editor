//
//  ProxyLogHandler.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Logging

public struct ProxyLogHandler: LogHandler {
    nonisolated private var _logLevel: Logger.Level
    nonisolated private var _metadata: Logger.Metadata
    nonisolated private var destinations: [any LogHandler]
    nonisolated public let label: String
    
    nonisolated public init(
        label: String,
        logLevel: Logger.Level? = nil,
        metadata: Logger.Metadata = [:],
        destinations: [any LogHandler]
    ) {
        self.label = label
        self.destinations = destinations
        self._logLevel = logLevel ?? destinations.map(\.logLevel).min() ?? .info
        self._metadata = metadata
        for index in self.destinations.indices {
            self.destinations[index].logLevel = self._logLevel
            self.destinations[index].metadata = metadata
        }
    }
    
    /// Inherited from `LogHandler.logLevel`.
    nonisolated public var logLevel: Logger.Level {
        get { _logLevel }
        set {
            _logLevel = newValue
            for index in destinations.indices {
                destinations[index].logLevel = newValue
            }
        }
    }
    
    /// Inherited from `LogHandler.metadata`.
    nonisolated public var metadata: Logger.Metadata {
        get { _metadata }
        set {
            _metadata = newValue
            for index in destinations.indices {
                destinations[index].metadata = newValue
            }
        }
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
        for destination in destinations {
            destination.log(
                level: level,
                message: message,
                metadata: metadata,
                source: source,
                file: file,
                function: function,
                line: line
            )
        }
    }
    
    /// Inherited from `LogHandler.subscript(metadataKey:)`.
    nonisolated public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { _metadata[key] }
        set {
            _metadata[key] = newValue
            for index in destinations.indices {
                destinations[index][metadataKey: key] = newValue
            }
        }
    }
}
