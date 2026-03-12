//
//  FilteredConsoleView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreSupport
import Logging
import SwiftUI

#if canImport(Shared)
import Shared
#endif

struct FilteredConsoleView: View {
    @Environment(Console.self) private var console
    @State private var logs: [Log] = []
    nonisolated let predicate: @Sendable (Log) -> Bool
    
    var body: some View {
        GroupBox("Filtered Console") {
            switch !logs.isEmpty {
            case true:
                ScrollView {
                    LazyVStack {
                        ForEach(logs) { log in
                            GroupBox {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(log.message.description)
                                        .font(.footnote)
                                        .fontWeight(.medium)
                                    if let metadata = log.metadata {
                                        ScrollView(.horizontal) {
                                            HStack {
                                                ForEach(Array(metadata), id: \.key) { metadata in
                                                    LabeledContent {
                                                        Text(metadata.value.description)
                                                            .font(.caption)
                                                            .fontDesign(.monospaced)
                                                            .fontWeight(.medium)
                                                            .foregroundStyle(.primary)
                                                    } label: {
                                                        Text(metadata.key)
                                                            .font(.caption2)
                                                            .foregroundStyle(.secondary)
                                                    }
                                                    .padding(4)
                                                    .background(.bar, in: .capsule)
                                                }
                                            }
                                        }
                                        .scrollIndicators(.hidden)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } label: {
                                Text(log.date.formatted(date: .abbreviated, time: .standard))
                                    .font(.caption)
                                    .fontWeight(.light)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .defaultScrollAnchor(.bottom, for: .alignment)
                .defaultScrollAnchor(.bottom, for: .initialOffset)
                .defaultScrollAnchor(.bottom, for: .sizeChanges)
                .scrollClipDisabled()
            case false:
                ContentUnavailableView("No Logs", systemImage: "terminal")
            }
        }
        .animation(.spring, value: logs)
        .task(id: console.filteredLogs) {
            let logs = self.console.logs
            Task { @DatabaseActor in
                let filteredLogs = logs.filter(predicate)
                await MainActor.run {
                    self.logs = filteredLogs
                }
            }
        }
    }
}
