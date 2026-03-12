//
//  Console.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Collections
import Foundation
import Logging
import Synchronization
import SwiftUI

@globalActor public actor ConsoleActor {
    nonisolated public static let shared: ConsoleActor = .init()
}

@MainActor @Observable public final class Console: Sendable {
    nonisolated public static let shared: Console = .init()
    #if swift(>=6.2)
    @ConsoleActor private let scheduler: MaintenanceScheduler = .init()
    #endif
    nonisolated private let maxLogs: Int = 1000
    @MainActor var task: Task<Void, any Swift.Error>?
    @MainActor public private(set) var filteredLogs: [Log] = []
    @MainActor @ObservationIgnored public var _logs: [Log] = []
    
    @MainActor @ObservationTracked public var logs: [Log] {
        get { _logs }
        set {
            guard _logs != newValue else { return }
            _logs = newValue
            if task == nil {
                refreshFilteredLogs(logs: newValue)
            }
        }
    }
    
    @MainActor var minimumLogLevel: Logger.Level = .debug {
        didSet(newValue) {
            persistLevel(newValue, forKey: .minimumLogLevel)
            refreshFilteredLogs()
        }
    }
    
    @MainActor var filterLogLevel: Logger.Level? {
        didSet(newValue) {
            persistOptionalLevel(newValue, forKey: .filterLogLevel)
            refreshFilteredLogs()
        }
    }
    
    @MainActor var filterText: String = "" {
        didSet(newValue) {
            persistString(newValue, forKey: .filterText)
            refreshFilteredLogs()
        }
    }
    
    @MainActor var filterLabels: String = "" {
        didSet(newValue) {
            persistString(newValue, forKey: .filterLabels)
            refreshFilteredLogs()
        }
    }
    
    @MainActor var filterSource: String = "" {
        didSet(newValue) {
            persistString(newValue, forKey: .filterSource)
            refreshFilteredLogs()
        }
    }
    
    @MainActor var filterFile: String = "" {
        didSet(newValue) {
            persistString(newValue, forKey: .filterFile)
            refreshFilteredLogs()
        }
    }
    
    @MainActor var filterFunction: String = "" {
        didSet(newValue) {
            persistString(newValue, forKey: .filterFunction)
            refreshFilteredLogs()
        }
    }
    
    nonisolated internal init() {
        Task { @MainActor in
            let store = UserDefaults.console ?? .standard
            if let data = store.data(forKey: Key.minimumLogLevel.rawValue),
               let object = try? JSONDecoder().decode(Logger.Level.self, from: data) {
                self.minimumLogLevel = object
            }
            if let data = store.data(forKey: Key.filterLogLevel.rawValue),
               let object = try? JSONDecoder().decode(Logger.Level.self, from: data) {
                self.filterLogLevel = object
            } else {
                self.filterLogLevel = nil
            }
            self.filterText = store.string(forKey: Key.filterText.rawValue) ?? ""
            self.filterLabels = store.string(forKey: Key.filterLabels.rawValue) ?? ""
            self.filterSource = store.string(forKey: Key.filterSource.rawValue) ?? ""
            self.filterFile = store.string(forKey: Key.filterFile.rawValue) ?? ""
            self.filterFunction = store.string(forKey: Key.filterFunction.rawValue) ?? ""
            self.refreshFilteredLogs()
        }
        #if swift(>=6.2)
        Task { @ConsoleActor in
            scheduler.start(every: 30 * 60) { @MainActor [weak self] in
                self?.maintenance()
            }
        }
        #endif
    }
    
    // FIXME: Crashes when logs are appended very fast.
    
    nonisolated internal func output(
        date: Date,
        level: Logging.Logger.Level,
        message: Logging.Logger.Message,
        metadata: Logging.Logger.Metadata?,
        label: String,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) async {
        await MainActor.run {
            task?.cancel()
            task = nil
            if logs.last?.message != message
                || logs.last?.label != label
                || logs.last?.source != source
                || logs.last?.level != level
                || logs.last?.file != file
                || logs.last?.function != function
                || logs.last?.line != line {
                logs.append(
                    .init(
                        date: date,
                        level: level,
                        message: message,
                        metadata: metadata,
                        label: label,
                        source: source,
                        file: file,
                        function: function,
                        line: line
                    )
                )
            }
        }
    }
    
    @MainActor
    private func refreshFilteredLogs(logs: [Log]? = nil) {
        task?.cancel()
        let logs = logs ?? self._logs
        let previousFilteredLogs = self.filteredLogs
        let fields = FilterFieldSnapshot(console: self)
        self.task = Task(priority: .userInitiated) { @ConsoleActor in
            let filteredLogs = try! logs.filter {
                matchesFilters($0, fields: fields)
            }
            guard filteredLogs != previousFilteredLogs else {
                await MainActor.run { task = nil }
                return
            }
            
            await MainActor.run {
                defer { task = nil }
                self.filteredLogs = filteredLogs
            }
        }
    }
    
    @MainActor
    func filteredOffset(for id: UUID) -> Int? {
        filteredLogs.firstIndex(where: { $0.id == id })
    }
    
    @MainActor
    private func persistLevel(_ value: Logger.Level, forKey key: Key) {
        let store = UserDefaults.console ?? .standard
        if let data = try? JSONEncoder().encode(value) {
            store.set(data, forKey: key.rawValue)
        } else {
            store.removeObject(forKey: key.rawValue)
        }
    }
    
    @MainActor
    private func persistOptionalLevel(_ value: Logger.Level?, forKey key: Key) {
        let store = UserDefaults.console ?? .standard
        guard let value else {
            store.removeObject(forKey: key.rawValue)
            return
        }
        if let data = try? JSONEncoder().encode(value) {
            store.set(data, forKey: key.rawValue)
        } else {
            store.removeObject(forKey: key.rawValue)
        }
    }
    
    @MainActor private func persistString(_ value: String, forKey key: Key) {
        let store = UserDefaults.console ?? .standard
        store.set(value, forKey: key.rawValue)
    }
    
    @MainActor func maintenance() {
        #if swift(>=6.2)
        logs.keepLast(maxLogs)
        #endif
    }
}


extension Console {
    internal struct FilterFieldSnapshot: Hashable, Sendable {
        nonisolated internal let minimumLogLevel: Logger.Level
        nonisolated internal let filterLogLevel: Logger.Level?
        nonisolated internal let filterText: String
        nonisolated internal let filterLabels: String
        nonisolated internal let filterSource: String
        nonisolated internal let filterFile: String
        nonisolated internal let filterFunction: String
        
        @MainActor internal init(console: Console) {
            self.minimumLogLevel = console.minimumLogLevel
            self.filterLogLevel = console.filterLogLevel
            self.filterText = console.filterText
            self.filterLabels = console.filterLabels
            self.filterSource = console.filterSource
            self.filterFile = console.filterFile
            self.filterFunction = console.filterFunction
        }
    }
    
    nonisolated internal func matchesFilters(
        _ log: Log,
        fields snapshot: FilterFieldSnapshot
    ) -> Bool {
        if Task.isCancelled { return false }
        let isFunctionFiltering = !snapshot.filterFunction.isEmpty
        
        if !isFunctionFiltering {
            guard log.level >= snapshot.minimumLogLevel else {
                return false
            }
            if let requiredLevel = snapshot.filterLogLevel {
                guard log.level == requiredLevel else {
                    return false
                }
            }
        }
        if Task.isCancelled { return false }
        if let selected = decodedLabelSelection(from: snapshot.filterLabels) {
            guard selected.contains(log.label) else {
                return false
            }
        }
        if !snapshot.filterSource.isEmpty {
            guard log.source == snapshot.filterSource else {
                return false
            }
        }
        if !snapshot.filterFile.isEmpty {
            guard log.file == snapshot.filterFile else {
                return false
            }
        }
        if !snapshot.filterFunction.isEmpty {
            guard log.function == snapshot.filterFunction else {
                return false
            }
        }
        if Task.isCancelled { return false }
        let searchTokens = snapshot.filterText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .map { $0.lowercased() }
        guard !searchTokens.isEmpty else {
            return true
        }
        if Task.isCancelled { return false }
        let haystack = searchableString(for: log)
        if Task.isCancelled { return false }
        return searchTokens.allSatisfy { haystack.contains($0) }
    }
    
    nonisolated private func searchableString(for log: Log) -> String {
        var parts: [String] = [
            log.date.formatted(date: .numeric, time: .standard),
            log.level.rawValue,
            log.label,
            log.source,
            log.file,
            log.function,
            String(log.line),
            log.message.description
        ]
        
        parts.append(contentsOf: metadataSearchParts(log.metadata))
        
        return parts
            .joined(separator: " ")
            .lowercased()
    }
    
    nonisolated private func decodedLabelSelection(from raw: String) -> Set<String>? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("["),
           let data = trimmed.data(using: .utf8),
           let array = try? JSONDecoder().decode([String].self, from: data) {
            return Set(array)
        }
        return [trimmed]
    }
    
    nonisolated private func metadataSearchParts(_ metadata: Logger.Metadata?) -> [String] {
        guard let metadata, !metadata.isEmpty else {
            return []
        }
        var parts: [String] = []
        parts.reserveCapacity(metadata.count * 3)
        for (key, value) in metadata {
            let rendered = renderMetadataValue(value)
            parts.append(key)
            parts.append(rendered)
            parts.append("\(key) = \(rendered)")
        }
        return parts
    }
    
    nonisolated private func renderMetadataValue(_ value: Logger.MetadataValue) -> String {
        switch value {
        case .string(let string):
            return string
        case .stringConvertible(let convertible):
            return convertible.description
        case .array(let array):
            return array.map(renderMetadataValue).joined(separator: " ")
        case .dictionary(let dictionary):
            return dictionary
                .map { "\($0.key) = \(renderMetadataValue($0.value))" }
                .joined(separator: " ")
        }
    }
}

extension Console {
    @MainActor
    internal func markViewed(id: UUID) {
        guard let index = self.logs.firstIndex(where: { $0.id == id }) else {
            return
        }
        guard logs[index].hasViewed == false else {
            return
        }
        var logs = self.logs
        logs[index].hasViewed = true
        self.logs = logs
        if let filteredIndex = self.filteredLogs.firstIndex(where: { $0.id == id }) {
            var filteredLogs = self.filteredLogs
            filteredLogs[filteredIndex].hasViewed = true
            self.filteredLogs = filteredLogs
        }
    }
    
    @MainActor
    internal func markViewed(around offset: Int, window: Int) {
        guard !filteredLogs.isEmpty,
              offset >= 0, offset < filteredLogs.count else {
            return
        }
        let lower = max(0, offset - window)
        let upper = min(filteredLogs.count - 1, offset + window)
        for index in lower...upper { markViewed(id: filteredLogs[index].id) }
    }
}

extension Console {
    @MainActor public var unviewedCount: Int {
        logs.reduce(into: 0) { count, log in
            if !log.hasViewed { count += 1 }
        }
    }
    
    @MainActor public var alertCount: Int {
        logs.reduce(into: 0) { count, log in
            if !log.hasViewed && (
                log.level == .critical ||
                log.level == .error ||
                log.level == .warning
            ) {
                count += 1
            }
        }
    }
    
    @MainActor public func resetRandomAlertViewedState(count: Int? = nil) {
        let candidates = logs.filter {
            $0.hasViewed && (
                $0.level == .critical ||
                $0.level == .error ||
                $0.level == .warning
            )
        }
        guard !candidates.isEmpty else { return }
        let requestedCount = count ?? Int.random(in: 1...min(10, candidates.count))
        let clampedCount = max(0, min(requestedCount, candidates.count))
        guard clampedCount > 0 else { return }
        let selectedIDs = Set(candidates.shuffled().prefix(clampedCount).map(\.id))
        var logs = self.logs
        for index in logs.indices {
            if selectedIDs.contains(logs[index].id) {
                logs[index].hasViewed = false
            }
        }
        self.logs = logs
        if !filteredLogs.isEmpty {
            var filteredLogs = self.filteredLogs
            for index in filteredLogs.indices {
                if selectedIDs.contains(filteredLogs[index].id) {
                    filteredLogs[index].hasViewed = false
                }
            }
            self.filteredLogs = filteredLogs
        }
    }
    
    @MainActor public func resetViewedState(for ids: some Sequence<UUID>) {
        let targets = Set(ids)
        guard !targets.isEmpty else { return }
        var logs = self.logs
        var didChange = false
        for index in logs.indices {
            if targets.contains(logs[index].id), logs[index].hasViewed {
                logs[index].hasViewed = false
                didChange = true
            }
        }
        guard didChange else { return }
        self.logs = logs
        if !filteredLogs.isEmpty {
            var filteredLogs = self.filteredLogs
            for index in filteredLogs.indices {
                if targets.contains(filteredLogs[index].id) {
                    filteredLogs[index].hasViewed = false
                }
            }
            self.filteredLogs = filteredLogs
        }
    }
    
    @MainActor
    public func resetRandomViewedState(
        count: Int? = nil,
        fromFilteredLogs: Bool = false
    ) {
        let source = fromFilteredLogs ? filteredLogs : logs
        guard !source.isEmpty else { return }
        let viewed = source.filter(\.hasViewed)
        let pool = viewed.isEmpty ? source : viewed
        guard !pool.isEmpty else { return }
        let requestedCount = count ?? Int.random(in: 1...min(25, pool.count))
        let clampedCount = max(0, min(requestedCount, pool.count))
        guard clampedCount > 0 else { return }
        let selected = Array(pool.shuffled().prefix(clampedCount))
        resetViewedState(for: selected.map(\.id))
    }
    
    @MainActor
    func resetAllViewedState() {
        guard logs.contains(where: \.hasViewed) else { return }
        var logs = self.logs
        for index in logs.indices {
            logs[index].hasViewed = false
        }
        self.logs = logs
        if !filteredLogs.isEmpty {
            var filteredLogs = self.filteredLogs
            for index in filteredLogs.indices {
                filteredLogs[index].hasViewed = false
            }
            self.filteredLogs = filteredLogs
        }
    }
    
    @MainActor
    func insertDemoAlerts(count: Int? = nil) {
        let count = count ?? Int.random(in: 1...5)
        let levels: [Logger.Level] = [.warning, .error, .critical]
        for index in 0..<count {
            logs.insert(
                .init(
                    date: .now,
                    level: levels.randomElement() ?? .error,
                    message: "Demo alert \(index + 1)",
                    metadata: [
                        "kind": .string("alert-test"),
                        "count": .string("\(count)")
                    ],
                    label: "com.asymbas.console.test",
                    source: "ConsoleTest",
                    file: "ConsoleView.swift",
                    function: "insertDemoAlerts",
                    line: 0
                ),
                at: 0
            )
        }
    }
}
