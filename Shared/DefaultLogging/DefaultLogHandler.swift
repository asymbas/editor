//
//  DefaultLogHandler.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Logging

public struct DefaultLogHandler: LogHandler {
    nonisolated private let mode: Mode?
    nonisolated private let output: Output?
    nonisolated private let includeMetadata: Bool
    nonisolated private let dateStyle: Date.FormatStyle.DateStyle
    nonisolated private let timeStyle: Date.FormatStyle.TimeStyle
    nonisolated private let destinations: [any LogDestination]
    nonisolated public let label: String
    /// Inherited from `LogHandler.metadata`.
    nonisolated public var metadata: Logger.Metadata = [:]
    /// Inherited from `LogHandler.logLevel`.
    nonisolated public var logLevel: Logger.Level = .debug
    
    nonisolated public init(
        label: String,
        mode: Mode? = nil,
        output: Output? = nil,
        isActive: Bool = false,
        includeMetadata: Bool = false,
        date dateStyle: Date.FormatStyle.DateStyle = .numeric,
        time timeStyle: Date.FormatStyle.TimeStyle = .standard,
        destinations: any LogDestination...
    ) {
        self.label = label
        self.includeMetadata = includeMetadata
        self.dateStyle = dateStyle
        self.timeStyle = timeStyle
        self.destinations = destinations
        self.output = output
        if !isActive {
            self.mode = nil
            return
        }
        guard let mode else {
            switch isatty(STDOUT_FILENO) {
            case 0: self.mode = .compiler
            case 1: self.mode = .default
            default: fatalError()
            }
            return
        }
        self.mode = mode
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
        #if RELEASE
        return
        #endif
        let date = Date.now
        if mode != nil {
            let formattedDate = date.formatted(date: dateStyle, time: timeStyle)
            var components = [
                formattedDate,
                "[\(level.rawValue.uppercased())]",
                "[\(source)]"
            ]
            if level == .trace, !function.isEmpty {
                components.append("[\(function)]")
            }
            if mode == .default {
                components = color(level: level, wrapping: { components })
            }
            components.append(message.description)
            if includeMetadata {
                var mergedMetadata = self.metadata
                if let metadata, !metadata.isEmpty {
                    mergedMetadata = self.metadata.merging(metadata) { $1 }
                }
                components.append(mergedMetadata.description)
            }
            let string = "\(components.joined(separator: " "))"
            switch output {
            case .fileHandler:
                if let data = string.data(using: .utf8) {
                    try? FileHandle.standardOutput.write(contentsOf: data)
                }
            case .cString:
                _ = string.withCString { write(STDOUT_FILENO, $0, strlen($0)) }
            case nil:
                print(string)
            }
        }
        guard !destinations.isEmpty else { return }
        Task.detached(priority: .utility) { @concurrent in
            for destination in destinations {
                await destination.log(
                    date: date,
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
    }
    
    /// Inherited from `LogHandler.subscript(metadataKey:)`.
    nonisolated public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }
    
    nonisolated private func color(level: Logger.Level, wrapping: () -> [String]) -> [String] {
        [startColor(level: level)] + wrapping() + [resetColor()]
    }
    
    nonisolated private func startColor(level: Logger.Level) -> String {
        switch level {
        case .trace: "\u{001B}[37m"
        case .debug: "\u{001B}[34m"
        case .info: "\u{001B}[32m"
        case .notice: "\u{001B}[36m"
        case .warning: "\u{001B}[33m"
        case .error: "\u{001B}[31m"
        case .critical: "\u{001B}[35m"
        }
    }
    
    nonisolated private func resetColor() -> String {
        "\u{001B}[0m"
    }
    
    public enum Mode: Sendable {
        case `default`
        case compiler
    }
    
    public enum Output: Sendable {
        case cString
        case fileHandler
    }
}

public protocol LogDestination: Sendable {
    @Sendable nonisolated func log(
        date: Date,
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) async
}
