//
//  HistoryTrackingTestView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import Logging
import SwiftData
import SwiftUI

#if canImport(Shared)
import Shared
#endif

struct HistoryTrackingTestView: View {
    @Environment(Library.self) private var library
    @Environment(Database.self) private var database
    @Environment(Observer.self) private var observer
    @Environment(\.modelContext) private var modelContext
    @State private var transactions: [DatabaseHistoryTransaction] = []
    @State private var filterText: String = ""
    @State private var limit: Int = 250
    @State private var expanded: Set<Int> = []
    @State private var isRefreshing: Bool = false
    
    var body: some View {
        List {
            Section {
                HStack {
                    Button(isRefreshing ? "Refreshing..." : "Refresh") {
                        Task { await refresh() }
                    }
                    .disabled(isRefreshing)
                    
                    Spacer()
                    
                    Text("\(filteredTransactions.count)")
                        .foregroundStyle(.secondary)
                }
                
                Stepper("Limit: \(limit)", value: $limit, in: 10...5000, step: 50)
                
                TextField("Filter (matches change description)", text: $filterText)
#if os(iOS)
                    .textInputAutocapitalization(.never)
#endif
                    .autocorrectionDisabled()
            }
            Section("Actions") {
                Button("Fetch with `FetchDescriptor`") {
                    Task { @MainActor in
                        do {
                            let key = library.id + "a"
                            let descriptor = HistoryDescriptor<DatabaseHistoryTransaction>(predicate: #Predicate {
                                $0.storeIdentifier == key
                            })
                            let results = try modelContext.fetchHistory(descriptor)
                            print(results)
                        } catch {
                            Banner(.error, "Fetch failed") { "\(error)" }
                        }
                    }
                }
                Button("Insert User + Post") {
                    Task { @MainActor in
                        do {
                            let user = User(name: "History \(randomName(length: 6))")
                            let profile = Profile(preferredName: "H \(randomName(length: 4))", user: user)
                            user.profile = profile
                            let post = Post(
                                title: "History \(randomName(length: 5))",
                                content: "Lorem \(randomName(length: 8))",
                                author: user
                            )
                            user.posts.append(post)
                            modelContext.insert(user)
                            try modelContext.save()
                        } catch {
                            Banner(.error, "Insert failed") { "\(error)" }
                        }
                    }
                }
                Button("Update Random User") {
                    Task { @MainActor in
                        do {
                            let users = try modelContext.fetch(FetchDescriptor<User>())
                            guard let user = users.randomElement() else {
                                Banner { "No users to update" }
                                return
                            }
                            user.name = "\(user.name) \(randomName(length: 3))"
                            try modelContext.save()
                        } catch {
                            Banner(.error, "Update failed") { "\(error)" }
                        }
                    }
                }
                Button("Delete Random User") {
                    Task { @MainActor in
                        do {
                            let users = try modelContext.fetch(FetchDescriptor<User>())
                            guard let user = users.randomElement() else {
                                Banner { "No users to delete" }
                                return
                            }
                            modelContext.delete(user)
                            try modelContext.save()
                        } catch {
                            Banner(.error, "Delete failed") { "\(error)" }
                        }
                    }
                }
            }
            Section("Transactions") {
                if filteredTransactions.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("No transactions found for the current filter.")
                    )
                } else {
                    ForEach(Array(filteredTransactions.enumerated()), id: \.offset) { index, transaction in
                        let isExpanded = Binding(
                            get: { expanded.contains(index) },
                            set: { value in
                                if value {
                                    expanded.insert(index)
                                } else {
                                    expanded.remove(index)
                                }
                            }
                        )
                        DisclosureGroup(isExpanded: isExpanded) {
                            ForEach(Array(transaction.changes.enumerated()), id: \.offset) { _, change in
                                VStack(alignment: .leading, spacing: 6) {
                                    switch change {
                                    case .insert(let history):
                                        Text("Insert")
                                            .fontWeight(.semibold)
                                        Text("\(String(describing: history))")
                                            .font(.footnote.monospaced())
                                            .foregroundStyle(.secondary)
                                    case .update(let history):
                                        Text("Update")
                                            .fontWeight(.semibold)
                                        Text("\(String(describing: history))")
                                            .font(.footnote.monospaced())
                                            .foregroundStyle(.secondary)
                                    case .delete(let history):
                                        Text("Delete")
                                            .fontWeight(.semibold)
                                        Text("\(String(describing: history))")
                                            .font(.footnote.monospaced())
                                            .foregroundStyle(.secondary)
                                    @unknown default:
                                        Text("Unknown")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        } label: {
                            HStack {
                                Text("Transaction \(index + 1)")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(transaction.changes.count) changes")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        .task(id: observer.lastUpdated) { await refresh() }
    }
    
    private var filteredTransactions: [DatabaseHistoryTransaction] {
        let base = Array(transactions.prefix(limit))
        guard filterText.isEmpty == false else { return base }
        return base.filter { transaction in
            transaction.changes.contains { change in
                let text = String(describing: change).lowercased()
                return text.contains(filterText.lowercased())
            }
        }
    }
    
    private func refresh() async {
        await MainActor.run { self.isRefreshing = true }
        defer { Task { @MainActor in self.isRefreshing = false } }
        do {
            let descriptor = HistoryDescriptor<DatabaseHistoryTransaction>()
            let history = try modelContext.fetchHistory(descriptor)
            await MainActor.run { self.transactions = history }
        } catch {
            Banner(.error, "History Fetch Error") {
                "Unable to fetch history: \(error)"
            }
        }
    }
}
