//
//  ConsoleView.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Logging
import SwiftUI

extension EnvironmentValues {
    @Entry internal var isPreviewing: Bool = false
}

extension EnvironmentValues {
    @Entry fileprivate
    var scrollPosition: Binding<ScrollPosition> = .constant(.init(idType: Int.self))
}

extension ConsoleView {
    nonisolated private static let isDebuggingScrollPosition: Bool = false
}

public struct ConsoleView: View {
    @Environment(Console.self) private var console: Console?
    @State private var scrollPosition: ScrollPosition = .init(idType: Int.self)
    @FocusState private var isFocused: Bool
    
    public init() {}
    
    public var body: some View {
        InnerView()
            .defaultAppStorage(.console ?? .standard)
            .environment(console ?? .shared)
    }
    
    struct InnerView: View {
        @Environment(Console.self) private var console
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @State private var scrollPosition: ScrollPosition = .init(idType: Int.self)
        @FocusState private var isFocused: Bool
        
        private let columnVisibility: NavigationSplitViewVisibility = {
#if os(iOS)
            .detailOnly
#else
            .automatic
#endif
        }()
        
        var body: some View {
            NavigationSplitView(
                columnVisibility: .constant(columnVisibility),
                preferredCompactColumn: .constant(.detail)
            ) {
                Text("")
            } detail: {
                VStack(alignment: .leading, spacing: 8) {
                    InlineToolbar(isFocused: $isFocused)
                        .safeAreaPadding()
                    LogsView()
                        .scrollTargetLayout(/*isEnabled: !isFocused*/)
                }
                .modifier(ScrollViewPosition(scrollPosition: $scrollPosition))
                .modifier(BottomInsetControlGroup(scrollPosition: $scrollPosition))
            }
        }
    }
    
    struct InlineToolbar: View {
        var isFocused: FocusState<Bool>.Binding
        
        var body: some View {
            HStack {
                FilterTextField()
                    .focused(isFocused)
                    .frame(maxWidth: .infinity)
                OptionsMenu()
                ClearButton()
                    .buttonStyle(.bordered)
            }
            .font(.caption)
            .lineLimit(1)
            .truncationMode(.head)
        }
    }
    
    struct BottomInsetControlGroup: ViewModifier {
        @Environment(Console.self) private var console
        @Binding var scrollPosition: ScrollPosition
        
        func body(content: Content) -> some View {
            content
                .safeAreaInset(edge: .bottom) {
                    HStack {
                        HStack {
                            if !console.filterText.isEmpty
                                || console.filterLogLevel != nil
                                || !console.filterSource.isEmpty
                                || !console.filterFile.isEmpty
                                || !console.filterFunction.isEmpty {
                                ClearButton()
                                    .transition(.scale)
                            }
                        }
                        .animation(.spring, value: console.filterText)
                        .animation(.spring, value: console.filterLogLevel)
                        .animation(.spring, value: console.filterSource)
                        .animation(.spring, value: console.filterFile)
                        .animation(.spring, value: console.filterFunction)
                        Spacer()
                        PositionView()
                        ScrollButton("Top", systemImage: "arrow.up", edge: .top)
                        ScrollButton("Bottom", systemImage: "arrow.down", edge: .bottom)
                    }
                    .buttonStyle(.borderedProminent)
                    .labelStyle(.iconOnly)
                    .frame(maxHeight: 30)
                    .safeAreaPadding()
                    .environment(\.scrollPosition, $scrollPosition)
                }
        }
    }
    
    struct FilterTextField: View {
        @Environment(Console.self) private var console: Console
        @State private var filterText: String = ""
        
        var body: some View {
            TextField("Filter...", text: $filterText)
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .disableAutocorrection(true)
                .onAppear {
                    self.filterText = console.filterText
                }
                .onChange(of: console.filterText) { _, newValue in
                    guard filterText != newValue else { return }
                    self.filterText = newValue
                }
                .task(id: filterText) {
                    try? await Task.sleep(for: .milliseconds(400))
                    self.console.filterText = filterText
                }
        }
    }
    
    struct ScrollButton: View {
        @Environment(\.scrollPosition) private var scrollPosition
        private var title: String
        private var systemImage: String
        private var edge: Edge
        
        init(_ title: String, systemImage: String, edge: Edge) {
            self.title = title
            self.systemImage = systemImage
            self.edge = edge
        }
        
        var body: some View {
            Button(title, systemImage: systemImage) {
                scrollPosition.wrappedValue.scrollTo(edge: edge)
            }
        }
    }
    
    struct ScrollViewPosition: ViewModifier {
        @Binding var scrollPosition: ScrollPosition
        
        @AppStorage(.lastScrollPosition, store: .console)
        private var lastScrollPosition: Int?
        
        func body(content: Content) -> some View {
            ScrollView {
                content
            }
            .scrollPosition($scrollPosition)
            .modifier(ScrollInteraction { scrollPosition.viewID(type: Int.self) })
            .onAppear {
                if let lastScrollPosition = self.lastScrollPosition {
                    scrollPosition.scrollTo(id: lastScrollPosition, anchor: .center)
                } else {
                    scrollPosition.scrollTo(edge: .bottom)
                }
            }
            .overlay {
                if ConsoleView.isDebuggingScrollPosition {
                    VStack {
                        if let lastScrollPosition = self.lastScrollPosition {
                            LabeledContent("Last Position") {
                                Text(lastScrollPosition.description)
                                    .bold()
                                    .foregroundStyle(.primary)
                            }
                        }
                        LabeledContent("Position") {
                            Text("\(scrollPosition.viewID(type: Int.self) ?? -1)")
                                .bold()
                                .foregroundStyle(.primary)
                        }
                    }
                    .monospacedDigit()
                    .frame(width: 150)
                    .padding()
                }
            }
        }
        
        struct ScrollInteraction: ViewModifier {
            @AppStorage(.lastScrollPosition, store: .console)
            private var lastScrollPosition: Int?
            let onChange: () -> Int?
            
            func body(content: Content) -> some View {
                content
                    .onScrollPhaseChange { _, newPhase in
                        if !newPhase.isScrolling, let newValue = onChange() {
                            self.lastScrollPosition = newValue
                        }
                    }
            }
        }
    }
    
    struct PositionView: View {
        @Environment(\.scrollPosition) private var scrollPosition
        
        @AppStorage(.lastScrollPosition, store: .console)
        private var lastScrollPosition: Int?
        
        var body: some View {
            let check = scrollPosition.wrappedValue.viewID(type: Int.self) != lastScrollPosition
            HStack {
                if let currentPosition = self.scrollPosition.wrappedValue.viewID(type: Int.self) {
                    HStack {
                        if let lastScrollPosition = self.lastScrollPosition,
                           currentPosition != lastScrollPosition {
                            Text("\(lastScrollPosition)")
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                    Text("\(currentPosition)")
                        .foregroundStyle(currentPosition != lastScrollPosition ? .yellow : .primary)
                }
            }
            .animation(.snappy, value: lastScrollPosition)
            .monospacedDigit()
            .bold()
            .foregroundStyle(.primary)
            .padding()
            .frame(height: 30)
            .background(.ultraThinMaterial, in: .buttonBorder)
            .colorScheme(check ? .dark : .light)
            .opacity(check == nil ? 0 : 1)
            .animation(
                .snappy,
                value: check
            )
        }
    }
    
    struct LogsView: View {
        @Environment(Console.self) private var console
        
        var body: some View {
            LazyVStack {
                let filteredLogs = console.filteredLogs
                ForEach(filteredLogs.indices, id: \.self) { index in
                    let log = filteredLogs[index]
                    MessageView(log: log)
                        .id(index)
                        .onAppear {
                            console.markViewed(id: log.id)
                        }
                    Divider()
                }
            }
        }
    }
    
    struct ClearButton: View {
        @Environment(Console.self) private var console
        
        var body: some View {
            Button("Clear") {
                console.filterText = ""
                console.filterLogLevel = nil
                console.filterSource = ""
                console.filterFile = ""
                console.filterLabels = ""
                console.filterFunction = ""
            }
        }
    }
    
    struct OptionsMenu: View {
        @Environment(Console.self) private var console
        
        var body: some View {
            @Bindable var console = self.console
            Menu {
                Section("Log Level") {
                    MinimumLogLevelPicker()
                        .pickerStyle(.palette)
                        #if os(iOS)
                        .menuActionDismissBehavior(.disabled)
                        #endif
                }
                Section("Filtering") {
                    FilterLogLevelPicker()
                    SourcePicker()
                    FilePicker()
                    LabelPicker()
                }
                .pickerStyle(.menu)
                #if os(iOS)
                .menuActionDismissBehavior(.disabled)
                #endif
                DetailedLogsToggle()
                InlineLoggerMetadataToggle()
                Divider()
                DemoLogButton()
                UnreadTestButton()
            } label: {
                Label {
                    if console.filterLogLevel != nil {
                        Text(console.filterLogLevel?.rawValue ?? "")
                            .textCase(.uppercase)
                            .font(.callout.weight(.bold))
                            .transition(.slide)
                    }
                } icon: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .imageScale(.large)
                        .fontWeight(.bold)
                }
                .foregroundStyle(console.filterLogLevel?.color ?? .accentColor)
                
            }.animation(.snappy, value: console.filterLogLevel)
        }
    }
    
    struct UnreadTestButton: View {
        @Environment(Console.self) private var console
        
        var body: some View {
            Menu("Test Unviewed") {
                Button("Random Unviewed (All Logs)") {
                    console.resetRandomViewedState()
                }
                Button("Random Unviewed (Filtered Logs)") {
                    console.resetRandomViewedState(fromFilteredLogs: true)
                }
                Button("Mark All Unviewed") {
                    console.resetAllViewedState()
                }
            }
        }
    }
    
    struct DemoLogButton: View {
        var body: some View {
            EmptyView()
        }
    }
    
    struct DetailedLogsToggle: View {
        @Environment(Console.self) private var console
        @AppStorage(.useDetailedLogging, store: .console)
        private var useDetailedLogging: Bool = true
        
        var body: some View {
            Toggle(isOn: $useDetailedLogging) {
                Text("Detailed Logging")
            }
        }
    }
    
    struct InlineLoggerMetadataToggle: View {
        @Environment(Console.self) private var console
        @AppStorage(.inlineLoggerMetadata, store: .console)
        private var inlineLoggerMetadata: Bool = false
        
        var body: some View {
            Toggle(isOn: $inlineLoggerMetadata) {
                Text("Inline Logger Metadata")
            }
        }
    }
    
    struct MinimumLogLevelPicker: View {
        @Environment(Console.self) private var console
        
        var body: some View {
            @Bindable var console = self.console
            Picker("Minimum Level", selection: $console.minimumLogLevel) {
                ForEach(Logger.Level.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        }
    }
    
    struct FilterLogLevelPicker: View {
        @Environment(Console.self) private var console
        
        var body: some View {
            @Bindable var console = self.console
            Picker("Filter by Level", selection: $console.filterLogLevel) {
                ForEach(Logger.Level.allCases) { option in
                    Text(option.rawValue).tag(option, includeOptional: true)
                }
                Divider()
                Text("All").tag(Optional<Logger.Level>.none)
            }
        }
    }
    
    struct SourcePicker: View {
        @Environment(Console.self) private var console
        
        private var sources: [String] {
            Array(Set(console.logs.map(\.source))).sorted()
        }
        
        var body: some View {
            @Bindable var console = self.console
            Picker("Filter by Source", selection: $console.filterSource) {
                Text("All").tag("")
                ForEach(sources, id: \.self) { source in
                    Text(source.isEmpty ? "(none)" : source).tag(source)
                }
            }
            .onChange(of: sources) { _, newValue in
                if !console.filterSource.isEmpty,
                   !newValue.contains(console.filterSource) {
                    console.filterSource = ""
                }
            }
        }
    }
    
    struct FilePicker: View {
        @Environment(Console.self) private var console
        
        private var files: [String] {
            Array(Set(console.logs.map(\.file))).sorted()
        }
        
        var body: some View {
            @Bindable var console = self.console
            Picker("Filter by File", selection: $console.filterFile) {
                Text("All").tag("")
                ForEach(files, id: \.self) { file in
                    Text(file.isEmpty ? "(none)" : file).tag(file)
                }
            }
            .onChange(of: files) { _, newValue in
                if !console.filterFile.isEmpty,
                   !newValue.contains(console.filterFile) {
                    console.filterFile = ""
                }
            }
        }
    }
    
    struct LabelPicker: View {
        @Environment(Console.self) private var console
        
        private var labels: [String] {
            Array(Set(console.logs.map(\.label))).sorted()
        }
        
        var body: some View {
            @Bindable var console = self.console
            Menu("Filter by Label") {
                Button("All") { console.filterLabels = "" }
                Button("Select None") {
                    store([], all: Set(labels))
                }
                Divider()
                ForEach(labels, id: \.self) { label in
                    Toggle(isOn: binding(for: label)) {
                        Text(label.isEmpty ? "(none)" : label)
                    }
                }
            }
            .onChange(of: labels) { _, newValue in
                pruneSelection(available: Set(newValue))
            }
        }
        
        private func binding(for label: String) -> Binding<Bool> {
            Binding(
                get: { selectedLabels()?.contains(label) ?? true },
                set: { newValue in
                    let all = Set(labels)
                    var selection = selectedLabels() ?? all
                    if newValue {
                        selection.insert(label)
                    } else {
                        selection.remove(label)
                    }
                    store(selection, all: all)
                }
            )
        }
        
        private func selectedLabels() -> Set<String>? {
            let trimmed = self.console.filterLabels.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            if trimmed.hasPrefix("["),
               let data = trimmed.data(using: .utf8),
               let array = try? JSONDecoder().decode([String].self, from: data) {
                return Set(array)
            }
            return [trimmed]
        }
        
        private func store(_ selection: Set<String>, all: Set<String>) {
            if selection == all {
                self.console.filterLabels = ""
                return
            }
            if let data = try? JSONEncoder().encode(selection.sorted()),
               let string = String(data: data, encoding: .utf8) {
                self.console.filterLabels = string
            } else {
                self.console.filterLabels = ""
            }
        }
        
        private func pruneSelection(available: Set<String>) {
            guard var selection = selectedLabels() else { return }
            selection = selection.intersection(available)
            store(selection, all: available)
        }
    }
    
    struct MessageView: View {
        @Environment(Console.self) private var console
        @Environment(\.colorScheme) private var colorScheme
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(\.isPreviewing) private var isPreviewing
        @State private var size: CGSize?
        var log: Log
        
        @AppStorage(.useDetailedLogging, store: .console)
        private var useDetailedLogging: Bool = true
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                #if DEBUG
                if ConsoleView.isDebuggingScrollPosition {
                    Text(log.id.uuidString)
                        .font(.caption.monospaced())
                }
                #endif
                HStack {
                    if !isPreviewing {
                        Text(log.date.formatted(date: .omitted, time: .standard))
                    } else {
                        Text("0:00:00 AM")
                    }
                    Text(log.level.rawValue)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(log.source)
                    Menu {
                        Section(log.label) {
                            Button("Print", systemImage: "printer") {
                                print(log.message)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                }
                .font(.caption2.monospaced())
                .fontWeight(.bold)
                .foregroundStyle(log.level.color)
                if useDetailedLogging {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(log.file)
                                .truncationMode(.tail)
                            Spacer()
                            if horizontalSizeClass != .compact {
                                functionButton()
                            }
                            Text("\(log.line)")
                                .padding(.horizontal, 5)
                                .foregroundStyle(colorScheme == .light ? .white : .black)
                                .background(
                                    log.level.color.opacity(0.9),
                                    in: .rect(cornerRadius: 5)
                                )
                        }
                        .lineLimit(1)
                        if horizontalSizeClass == .compact {
                            functionButton()
                        }
                    }
                    .padding(15)
                    .font(.caption.monospaced())
                    .foregroundStyle(log.level.color.mix(
                        with: .secondary,
                        by: 0.9,
                        in: .perceptual
                    ).blendMode(colorScheme == .light ? .plusDarker : .plusLighter))
                    .background(
                        log.level.color.mix(
                            with: colorScheme == .light ? .white : .black,
                            by: 0.5,
                            in: .perceptual
                        ).opacity(colorScheme == .light ? 0.5 : 1.0),
                        in: .rect(cornerRadius: 12)
                    )
                }
                Text(log.message.description)
                    .font(.system(size: Self.fontSize, weight: .medium, design: .monospaced))
                if let metadata = self.log.metadata {
                    MetadataView(metadata: metadata)
                }
            }
            .safeAreaPadding(.horizontal)
            .textSelection(.enabled)
            .frame(minWidth: size?.width, minHeight: size?.height)
            .onGeometryChange(for: CGSize.self, of: \.size) { _, newValue in
                self.size = newValue
            }
        }
        
        @ViewBuilder private func functionButton() -> some View {
            Button {
                if console.filterFunction == self.log.function {
                    self.console.filterFunction = ""
                } else {
                    self.console.filterFunction = log.function
                    self.console.filterLogLevel = nil
                }
            } label: {
                Text(log.function)
                    .truncationMode(.middle)
                    .foregroundStyle(
                        console.filterFunction == log.function
                        ? AnyShapeStyle(.yellow)
                        : AnyShapeStyle(.link)
                    )
            }
            .buttonStyle(.plain)
        }
        
        @MainActor private static let fontSize: CGFloat = {
            #if os(iOS)
            15
            #else
            12
            #endif
        }()
        
        struct MetadataView: View {
            @Environment(\.horizontalSizeClass) private var horizontalSizeClass
            @State private var sorted: [Dictionary<String, Logger.MetadataValue>.Element] = []
            nonisolated var metadata: Logger.Metadata
            
            @AppStorage(.inlineLoggerMetadata)
            private var inlineLoggerMetadata: Bool = false
            
            private var rows: [GridItem] {
                [
                    .init(.flexible(), spacing: 8.0, alignment: .top),
                    .init(.flexible(), spacing: 8.0, alignment: .top)
                ]
            }
            
            var body: some View {
                if !sorted.isEmpty {
                    if !inlineLoggerMetadata {
                        switch horizontalSizeClass {
                        case .compact:
                            ForEach(sorted, id: \.key) { metadata in
                                GroupBox(metadata.key) {
                                    Text(metadata.value.description)
                                }
                                .groupBoxStyle(MonospacedGroupBoxStyle())
                            }
                        default:
                            ScrollView(.horizontal) {
                                LazyHGrid(rows: rows, alignment: .top, spacing: 8.0) {
                                    ForEach(sorted, id: \.key) { metadata in
                                        GroupBox(metadata.key) {
                                            Text(metadata.value.description)
                                        }
                                        .groupBoxStyle(MonospacedGroupBoxStyle())
                                    }
                                }
                                .frame(maxHeight: .infinity, alignment: .topLeading)
                            }
                        }
                    } else {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(sorted, id: \.key) { metadata in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(metadata.key)
                                            .font(.caption2.bold().monospaced())
                                            .foregroundStyle(.secondary)
                                        Text(metadata.value.description)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .fontDesign(.monospaced)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(in: .rect(cornerRadius: 8))
                                    .backgroundStyle(.regularMaterial)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                } else if !metadata.isEmpty {
                    ProgressView()
                        .task { @ConsoleActor in
                            let metadata = self.metadata
                                .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
                            Task { @MainActor in self.sorted = metadata }
                        }
                }
            }
        }
    }
}
