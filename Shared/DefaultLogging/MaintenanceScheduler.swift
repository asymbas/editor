//
//  MaintenanceScheduler.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension RangeReplaceableCollection where Self: RandomAccessCollection {
    nonisolated public mutating func keepLast(_ maxCount: Int) {
        guard maxCount > 0 else {
            removeAll()
            return
        }
        let extra = self.count - maxCount
        guard extra > 0 else { return }
        let cut = index(startIndex, offsetBy: extra)
        removeSubrange(startIndex..<cut)
    }
}

@ConsoleActor public final class MaintenanceScheduler: Sendable {
    private var task: Task<Void, Never>?
    
    nonisolated public init() {}
    
    public func start(
        every interval: TimeInterval,
        action: @escaping @Sendable @isolated(any) () -> Void
    ) {
        stop()
        let clampedInterval = max(0, interval)
        self.task = Task {
            await action()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(clampedInterval))
                await action()
            }
        }
    }
    
    public func stop() {
        task?.cancel()
        self.task = nil
    }
}
