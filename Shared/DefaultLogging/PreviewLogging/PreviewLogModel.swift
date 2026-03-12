//
//  PreviewLogStore.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Logging
import SwiftUI

extension PreviewLogView {
    @MainActor @Observable final class Model: Sendable {
        @MainActor static let shared: Model = .init()
        private(set) var entries: [Log] = []
        private(set) var recentEntries: [Log] = []
        private let maxEntries: Int = 200
        private let maxRecent: Int = 80
        var isPinned: Bool = false
        var clearDueDate: Date?
        let clearInterval: TimeInterval = 10
        private var clearWorkItem: DispatchWorkItem?
        
        private init() {}
        
        /// Append a new log entry (must be called on main thread).
        @concurrent func append(
            level: Logger.Level,
            message: Logger.Message,
            metadata: Logger.Metadata?
        ) async {
            let entry = Log(
                date: .now,
                level: level,
                message: message,
                metadata: metadata,
                label: "",
                source: "",
                file: "",
                function: "",
                line: 0,
                hasViewed: false
            )
            var entries = await self.entries
            var recentEntries = await self.recentEntries
            entries.append(entry)
            if entries.count > maxEntries {
                entries.removeFirst(entries.count - maxEntries)
            }
            recentEntries.append(entry)
            if recentEntries.count > maxRecent {
                recentEntries.removeFirst(recentEntries.count - maxRecent)
            }
            await MainActor.run {
                self.entries = entries
                self.recentEntries = recentEntries
                scheduleClear()
            }
        }
        
        /// Entries that should currently be visible in the overlay.
        var visibleEntries: [Log] {
            isPinned ? entries : recentEntries
        }
        
        func dismissOverlay() {
            clearWorkItem?.cancel()
            withAnimation {
                recentEntries.removeAll()
                self.isPinned = false
                self.clearDueDate = nil
            }
        }
        
        /// Clears recent entries after 10 seconds of silence (if not pinned).
        private func scheduleClear() {
            clearWorkItem?.cancel()
            let dueDate = Date().addingTimeInterval(clearInterval)
            self.clearDueDate = dueDate
            let workItem = DispatchWorkItem { [weak self] in
                guard let self else { return }
                if self.isPinned { return }
                withAnimation {
                    self.recentEntries.removeAll()
                    self.clearDueDate = nil
                }
            }
            self.clearWorkItem = workItem
            DispatchQueue.main.asyncAfter(
                deadline: .now() + clearInterval,
                execute: workItem
            )
        }
    }
}
