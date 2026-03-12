//
//  TableView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreRuntime
import SwiftData
import SwiftUI

#if canImport(Shared)
import Shared
#endif

extension TableView {
    func foreignKeyViolations(_ foreignKeyViolations: [ConstraintViolation]) -> Self {
        var copy = self
        copy.foreignKeyViolations = foreignKeyViolations
        return copy
    }
    
    func uniqueViolations(_ uniqueViolations: [ConstraintViolation]) -> Self {
        var copy = self
        copy.uniqueViolations = uniqueViolations
        return copy
    }
}

extension View where Self == TableView {
    func column(maxWidth: CGFloat?) -> some View {
        environment(\.columnMaxWidth, maxWidth)
    }
}

struct TableRowSelection: Hashable {
    var tableName: String
    var primaryKey: String
}

extension View {
    func selectedTableViewRow(_ binding: Binding<TableRowSelection?>) -> some View {
        environment(\.selectedRow, binding)
    }
}

extension EnvironmentValues {
    @Entry fileprivate var table: String?
    @Entry fileprivate var selectedRow: Binding<TableRowSelection?> = .constant(nil)
    @Entry fileprivate var columnMaxWidth: CGFloat?
    @Entry fileprivate var verticalSpacing: CGFloat = 4
    @Entry fileprivate var horizontalSpacing: CGFloat = 8
    @Entry fileprivate var rows: [[String: any Sendable]] = []
    @Entry fileprivate var foreignKeyViolationsMap: [Int64: ConstraintViolation] = [:]
}

extension ContainerValues {
    @Entry fileprivate var column: String?
    @Entry fileprivate var columnName: String?
    @Entry fileprivate var columnValue: String?
}

struct TableView: View {
    var table: String
    var rows: [[String: any Sendable]]
    var foreignKeyViolations: [ConstraintViolation] = []
    var uniqueViolations: [ConstraintViolation] = []
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                TableHeader(name: table, count: rows.count) {
                    if !foreignKeyViolations.isEmpty {
                        Text("\(foreignKeyViolations.count)")
                            .alertBadgeContainer(color: .red)
                    }
                    if !uniqueViolations.isEmpty {
                        Text("\(uniqueViolations.count)")
                            .alertBadgeContainer(color: .yellow)
                    }
                }
                if !rows.isEmpty {
                    TableBody(
                        foreignKeyViolations: foreignKeyViolations,
                        uniqueViolations: uniqueViolations
                    )
                    .environment(\.table, table)
                    .environment(\.rows, rows)
                } else {
                    Text("Empty")
                        .font(.footnote)
                        .foregroundStyle(.placeholder)
                }
            }
            .padding(12)
        }
        #if os(macOS)
        .scrollContentBackground(.hidden)
        #endif
        .background(in: .rect)
        .backgroundStyle(.background.secondary)
        .compositingGroup()
        .clipShape(.rect(cornerRadius: 12))
    }
    
    struct TableHeader<Content: View>: View {
        var name: String
        var count: Int
        @ViewBuilder var content: Content
        
        var body: some View {
            HStack {
                Text(name).font(Self.font)
                Spacer()
                content
                Text("\(count)").foregroundStyle(.secondary)
            }
        }
        
        @MainActor private static var font: Font {
            #if os(macOS)
            .headline.weight(.medium)
            #else
            .headline.bold()
            #endif
        }
    }
    
    struct TableBody: View {
        @Environment(\.selectedRow) private var selectedRow
        @Environment(\.table) private var table
        @Environment(\.rows) private var rows: [[String: any Sendable]]
        @State private var columns: [String] = []
        @State private var shouldExpand: Bool = false
        @State private var selectedViolation: ConstraintViolation?
        @State private var foreignKeyViolationsMap: [Int64: ConstraintViolation] = [:]
        var foreignKeyViolations: [ConstraintViolation]
        var uniqueViolations: [ConstraintViolation]
        
        @AppStorage("show-constraint-violations")
        private var showConstraintViolations: Bool = true
        
        var body: some View {
            ScrollView(.horizontal) {
                VStack(alignment: .leading) {
                    ColumnLayout {
                        ForEach(columns, id: \.self) { column in
                            if column != "rowid" {
                                RowContent(column: column) { pk, value, violation in
                                    Button(value.isEmpty ? "\"\"" : value) {
                                        if let violation = violation {
                                            self.selectedViolation = violation
                                        } else {
                                            if column == "pk" {
                                                if selectedRow.wrappedValue?.primaryKey == pk {
                                                    selectedRow.wrappedValue = nil
                                                    Banner(edge: .top, "Unselected Row") {
                                                        "Primary Key:\n\(value)"
                                                    }
                                                } else {
                                                    selectedRow.wrappedValue = .init(
                                                        tableName: table ?? "nil",
                                                        primaryKey: pk
                                                    )
                                                    Banner.info("Selected Row", edge: .top) {
                                                        "Primary Key:\n\(value)"
                                                    }
                                                }
                                            } else {
                                                shouldExpand.toggle()
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(
                                        selectedRow.wrappedValue?.primaryKey == pk ? .blue
                                        : value == "\(NSNull())"
                                        ? .secondary : .primary
                                    )
                                }
                                .containerValue(\.column, column)
                                .environment(\.foreignKeyViolationsMap, foreignKeyViolationsMap)
                            }
                        }
                        if !uniqueViolations.isEmpty && showConstraintViolations {
                            VStack(alignment: .leading) {
                                ForEach(uniqueViolations) { violation in
                                    Text("UNIQUE: \(violation.header)")
                                        .font(.footnote.monospaced())
                                        .foregroundStyle(.orange)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                            .containerValue(\.column, "UNIQUE")
                        }
                    }
                }
            }
            .defaultScrollAnchor(.leading)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .task {
                guard let row = self.rows.first else { return }
                self.columns = Array(row.keys).sorted { lhs, rhs in
                    if lhs == "pk" { return true }
                    if rhs == "pk" { return false }
                    if lhs == "rowid" { return true }
                    if rhs == "rowid" { return false }
                    return lhs < rhs
                }
            }
            .task(id: foreignKeyViolations) {
                self.foreignKeyViolationsMap = Dictionary(
                    grouping: foreignKeyViolations,
                    by: { $0.rowid ?? -1 }
                ).compactMapValues(\.first)
            }
            .popover(item: $selectedViolation) { violation in
                PopoverContent(violation: violation)
                    .font(.footnote)
                    .safeAreaPadding()
                    .presentationCompactAdaptation(.popover)
            }
        }
    }
    
    struct PopoverContent: View {
        var violation: ConstraintViolation
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("FOREIGN KEY violation")
                    .font(.headline)
                Text(violation.header)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.red)
                if let parent = self.violation.parentTable {
                    LabeledContent("Parent", value: "\(parent)")
                }
                if let rowID = self.violation.rowid {
                    LabeledContent("Row ID", value: "\(rowID)")
                }
                if let fkID = self.violation.fkid {
                    LabeledContent("Foreign Key (Row ID)", value: "\(fkID)")
                }
            }
            .labeledContentStyle(DefaultLabeledContentStyle())
        }
    }
    
    struct DefaultLabeledContentStyle: LabeledContentStyle {
        func makeBody(configuration: Self.Configuration) -> some View {
            HStack {
                configuration
                    .label
                Spacer()
                configuration
                    .content
                    .fontWeight(.medium)
                    .monospaced()
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ColumnLayout<Column: View>: View {
    @Environment(\.columnMaxWidth) private var columnMaxWidth
    @Environment(\.verticalSpacing) private var verticalSpacing
    @Environment(\.horizontalSpacing) private var horizontalSpacing
    @State private var maxSizes: [String: CGFloat] = [:]
    @State private var minSizes: [String: CGFloat] = [:]
    var columnSpacing: CGFloat = 20
    @ViewBuilder let content: Column
    
    private func applyMaxWidth(_ width: CGFloat) -> CGFloat {
        guard width.isFinite else { return 0 }
        if let columnMaxWidth = self.columnMaxWidth {
            return min(columnMaxWidth, width)
        }
        return width
    }
    
    private func resolvedWidth(_ column: String) -> CGFloat {
        let headerWidth = minSizes[column] ?? 10
        let contentWidth = maxSizes[column] ?? 0
        return applyMaxWidth(max(headerWidth, contentWidth))
    }
    
    var body: some View {
        Group(subviews: content) { subviews in
            VStack(alignment: .leading, spacing: verticalSpacing) {
                HStack(spacing: columnSpacing) {
                    ForEach(subviews: subviews) { subview in
                        if let column = subview.containerValues.column {
                            Text(column)
                                .font(.caption.weight(.bold).monospaced())
                                .foregroundStyle(column == "pk" ? Color.accentColor : .primary)
                                .onFixedSizeGeometryChange { _, newValue in
                                    minSizes[column] = applyMaxWidth(newValue)
                                }
                                .frame(width: resolvedWidth(column), alignment: .leading)
                        }
                    }
                }
                .modifier(HeaderBar())
                HStack(spacing: columnSpacing) {
                    ForEach(subviews: content) { subview in
                        if let column = subview.containerValues.column {
                            subview
                                .onFixedSizeGeometryChange { _, newValue in
                                    let headerWidth = minSizes[column] ?? 10
                                    let candidate = applyMaxWidth(max(headerWidth, newValue))
                                    maxSizes[column] = max(maxSizes[column] ?? 0, candidate)
                                }
                                .frame(width: resolvedWidth(column), alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, horizontalSpacing)
                .font(.footnote.monospaced())
            }
            .lineLimit(1)
            .truncationMode(.tail)
        }
    }
    
    struct HeaderBar: ViewModifier {
        @Environment(\.horizontalSpacing) private var horizontalSpacing
        
        func body(content: Content) -> some View {
            content
                .padding(.vertical, 2)
                .padding(.horizontal, horizontalSpacing)
                .background(.gray.opacity(0.15))
                .cornerRadius(4)
        }
    }
}

struct RowContent<Content: View>: View {
    @Environment(\.verticalSpacing) private var verticalSpacing
    @Environment(\.horizontalSpacing) private var horizontalSpacing
    @Environment(\.rows) private var rows: [[String: any Sendable]]
    @Environment(\.foreignKeyViolationsMap) private var foreignKeyViolationsMap
    var column: String
    @ViewBuilder let content: (String, String, ConstraintViolation?) -> Content
    
    @AppStorage("show-constraint-violations")
    private var showConstraintViolations: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: verticalSpacing) {
            ForEach(rows.indices, id: \.self) { index in
                let row = self.rows[index]
                let rowID = (row["rowid"] as? Int64) ?? -1
                let pk = row["pk"].map { "\($0)" } ?? ""
                let violation = showConstraintViolations ? foreignKeyViolationsMap[rowID] : nil
                let value = row[column].map { "\($0)" } ?? "ERROR"
                HStack(spacing: horizontalSpacing) {
                    content(pk, value, violation)
                        .highlight(isActive: violation != nil && showConstraintViolations)
                }
            }
        }
    }
}
