//
//  DatabaseTableView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import DataStoreRuntime
import DataStoreSQL
import DataStoreSupport
import SwiftData
import SwiftUI

#if canImport(Shared)
import Shared
#endif

#Preview(traits: .defaultData, .sizeThatFitsLayout) {
    DatabaseTableView(table: "User")
        .frame(maxWidth: 500, maxHeight: 400)
        .safeAreaPadding()
}

struct DatabaseTableView: View {
    @Environment(Observer.self) private var observer
    @State private var rows: [[String: any Sendable]] = []
    @State private var foreignKeyViolations: [ConstraintViolation] = []
    @State private var uniqueViolations: [ConstraintViolation] = []
    nonisolated var table: String
    
    var body: some View {
        TableView(table: table, rows: rows)
            .foreignKeyViolations(foreignKeyViolations)
            .uniqueViolations(uniqueViolations)
            .column(maxWidth: 400)
            .onDataStoreChange { store in
                do {
                    let rows = try store.queue.reader { connection in
                        try connection.query("SELECT rowid, * FROM \(quote(table))")
                    }
                    await MainActor.run {
                        self.rows = rows
                    }
                } catch {
                    Banner(.error, "Fetch Error") {
                        "Unable to fetch \(table) table: \(error)"
                    }
                }
            }
            .task(id: observer.violations) {
                let violations = self.observer.violations
                await DatabaseActor.run {
                    let foreignKeyViolations = Dictionary(
                        grouping: violations.filter { $0.kind == .foreignKey },
                        by: \.table
                    )[table] ?? []
                    let uniqueViolations = Dictionary(
                        grouping: violations.filter { $0.kind == .unique },
                        by: \.table
                    )[table] ?? []
                    if !foreignKeyViolations.isEmpty || !uniqueViolations.isEmpty {
                        await MainActor.run {
                            self.foreignKeyViolations = foreignKeyViolations
                            self.uniqueViolations = uniqueViolations
                        }
                    }
                }
            }
    }
}
