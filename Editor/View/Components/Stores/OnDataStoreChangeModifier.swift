//
//  OnDataStoreChangeModifier.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import SwiftData
import SwiftUI

extension View {
    func onDataStoreChange() -> some View {
        modifier(OnDataStoreChangeModifier({ _ in () }))
    }
    
    func onDataStoreChange(_ action: @escaping @DatabaseActor (DatabaseStore) async -> Void) -> some View {
        modifier(OnDataStoreChangeModifier({ await action($0) }))
    }
}

struct OnDataStoreChangeModifier: ViewModifier {
    @Environment(Database.self) private var database
    @Environment(Observer.self) private var observer
    @DatabaseActor @State private var isLoading: Bool = false
    @DatabaseActor @State private var task: Task<Void, any Swift.Error>?
    nonisolated let action: @DatabaseActor (DatabaseStore) async -> Void
    
    nonisolated init(_ action: @escaping @DatabaseActor (DatabaseStore) async -> Void) {
        self.action = action
    }
    
    func body(content: Content) -> some View {
        content
            .task(id: observer.lastUpdated) { @DatabaseActor in
                guard !isLoading, task == nil else {
                    return
                }
                self.task?.cancel()
                self.isLoading = true
                self.task = Task { @DatabaseActor in
                    await database.withDataStore { store in
                        if task?.isCancelled == true { return }
                        await action(store)
                    }
                    self.isLoading = false
                    self.task = nil
                }
            }
    }
}
