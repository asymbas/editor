//
//  PreviewLogView.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Logging
import SwiftUI

nonisolated let logger: Logger = .init(label: "com.asymbas.shared")

#Preview {
    List(Logger.Level.allCases) { level in
        Button("\(level.rawValue.capitalized) Log") {
            logger.log(level: level, "\(level.rawValue.capitalized)")
        }
    }.loggerPreviewAttachment(isEnabled: true)
}

struct PreviewLogView: View {
    @State private var view: Model = .shared
    
    var body: some View {
        LogsView()
            .modifier(DismissProgressBarModifier())
            .safeAreaInset(edge: .bottom) {
                if view.isPinned { Toolbar() }
            }
            .modifier(PinButtonModifier())
            .environment(view)
            .defaultAppStorage(.preview ?? .standard)
    }
    
    struct LogsView: View {
        @Environment(Model.self) private var view
        
        @AppStorage(.minimumLogLevel, store: .preview)
        private var minimumLogLevel: Logger.Level = .notice
        
        @AppStorage(.filterLogLevel, store: .preview)
        private var filterLogLevel: Logger.Level?
        
        @AppStorage(.filterText, store: .preview)
        private var filterText: String = ""
        
        var body: some View {
            VStack {
                let entries = self.filteredEntries
                let gradientOpacity = min(0.9, 0.15 * sqrt(Double(max(entries.count, 1))))
                if !entries.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(entries) { entry in
                                MessageView(log: entry)
                            }
                        }
                        .safeAreaPadding()
                        .frame(maxWidth: .infinity)
                        .animation(.spring(duration: 0.2), value: entries.count)
                    }
                    .defaultScrollAnchor(.bottom)
                    .scrollClipDisabled()
                    .background(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(
                                    color: .black.opacity(gradientOpacity),
                                    location: 0.0
                                ),
                                .init(
                                    color: .black.opacity(gradientOpacity * 0.7),
                                    location: 0.4
                                ),
                                .init(
                                    color: .black.opacity(0.0),
                                    location: 1.0
                                )
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(view.isPinned ? true : false)
                }
            }
            .animation(.spring, value: view.isPinned)
        }
        
        private var searchTokens: [String] {
            filterText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .split(whereSeparator: { $0.isWhitespace })
                .map { $0.lowercased() }
        }
        
        private func searchableString(for log: Log) -> String {
            var components: [String] = [
                log.date.formatted(date: .numeric, time: .standard),
                log.level.rawValue,
                log.message.description
            ]
            if let metadata = log.metadata, !metadata.isEmpty {
                let metadataString = metadata
                    .map { "\($0.key) = \($0.value)" }
                    .joined(separator: " ")
                components.append(metadataString)
            }
            return components.joined(separator: " ").lowercased()
        }
        
        private func matchesFilters(_ log: Log) -> Bool {
            guard log.level >= minimumLogLevel else {
                return false
            }
            if let requiredLevel = self.filterLogLevel {
                guard log.level == requiredLevel else {
                    return false
                }
            }
            let tokens = self.searchTokens
            guard !tokens.isEmpty else {
                return true
            }
            let haystack = searchableString(for: log)
            return tokens.allSatisfy { haystack.contains($0) }
        }
        
        private var filteredEntries: [Log] {
            let base = view.isPinned ? view.entries : view.recentEntries
            #if swift(>=6.2)
            return base.filter(matchesFilters)
            #else
            return try! base.filter(matchesFilters)
            #endif
        }
    }
    
    struct MessageView: View {
        @Environment(Model.self) private var view
        var log: Log
        
        var body: some View {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Timestamp(level: log.level, date: log.date)
                LevelBadge(level: log.level)
                MessageBody(message: log.message.description)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.black.opacity(view.isPinned ? 0.6 : 0.3))
            .clipShape(.rect(cornerRadius: 8, style: .continuous))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        struct Timestamp: View {
            @Environment(Model.self) private var view
            var level: Logger.Level
            var date: Date
            
            var body: some View {
                Text(date.formatted(date: .omitted, time: .standard))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(level.color.opacity(view.isPinned ? 1.0 : 0.9))
                    .blendMode(view.isPinned ? .normal : .plusLighter)
            }
        }
        
        struct LevelBadge: View {
            @Environment(Model.self) private var view
            var level: Logger.Level
            
            var body: some View {
                Text(level.rawValue)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .blendMode(.plusDarker)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(level.color.opacity(view.isPinned ? 0.8 : 0.5))
                    .cornerRadius(3)
            }
        }
        
        struct MessageBody: View {
            @Environment(Model.self) private var view
            var message: String
            
            var body: some View {
                Text(LocalizedStringKey(message))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white)
                    .blendMode(view.isPinned ? .normal : .plusLighter)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    struct Toolbar: View {
        var body: some View {
            HStack(spacing: 8) {
                FilterTextField()
                OptionMenu()
                    .labelStyle(.iconOnly)
                ClearButton()
                    .buttonStyle(.bordered)
            }
            .imageScale(.large)
            .font(.caption)
            .padding(8)
            .background(.bar)
            .colorScheme(.dark)
            .clipShape(.rect(cornerRadius: 12))
            .safeAreaPadding()
        }
    }
    
    struct ClearButton: View {
        @AppStorage(.filterLogLevel) private var filterLogLevel: Logger.Level?
        @AppStorage(.filterText) private var filterText: String = ""
        
        var body: some View {
            Button("Clear") {
                self.filterLogLevel = nil
                self.filterText = ""
            }
        }
    }
    
    struct OptionMenu: View {
        var body: some View {
            Menu("Options", systemImage: "ellipsis.circle") {
                Section("Minimum Level") {
                    MinimumLogLevelPicker()
                        .pickerStyle(.palette)
                }
                Section("Filter") {
                    FilterLogLevelPicker()
                        .pickerStyle(.menu)
                }
            }
            #if os(iOS)
            .menuActionDismissBehavior(.disabled)
            #endif
        }
    }
    
    struct MinimumLogLevelPicker: View {
        @AppStorage(.minimumLogLevel) private var minimumLogLevel: Logger.Level = .notice
        
        var body: some View {
            Picker("Minimum Level", selection: $minimumLogLevel) {
                ForEach(Logger.Level.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        }
    }
    
    struct FilterLogLevelPicker: View {
        @AppStorage(.filterLogLevel) private var filterLogLevel: Logger.Level?
        
        var body: some View {
            Picker("Filter by Level", selection: $filterLogLevel) {
                ForEach(Logger.Level.allCases) { option in
                    Text(option.rawValue).tag(option, includeOptional: true)
                }
                Divider()
                Text("All").tag(Optional<Logger.Level>.none)
            }
        }
    }
    
    struct FilterTextField: View {
        @AppStorage(.filterText) private var logFilterText: String = ""
        
        var body: some View {
            Image(systemName: "line.3.horizontal.decrease.circle")
            TextField(
                "Filter",
                text: $logFilterText,
                prompt: Text("Filter...").bold().foregroundStyle(.white.opacity(0.5))
            )
            .textFieldStyle(.plain)
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
            .disableAutocorrection(true)
        }
    }
    
    struct PinButtonModifier: ViewModifier {
        @Environment(Model.self) private var view
        
        func body(content: Self.Content) -> some View {
            ZStack(alignment: .topTrailing) {
                content
                Button{
                    view.isPinned.toggle()
                } label: {
                    Group {
                        if !view.isPinned {
                            Circle()
                                .fill(view.isPinned ? .green : .gray.opacity(0.7))
                                .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 0.5))
                                .frame(width: 12)
                                .frame(height: 24)
                                .contentShape(Rectangle())
                                .transition(.asymmetric(insertion: .slide, removal: .scale))
                        } else {
                            HStack {
                                Text("Dismiss")
                                    .font(.caption.bold())
                                    .textCase(.uppercase)
                                Image(systemName: "chevron.down")
                                    .fontWeight(.medium)
                                    .imageScale(.medium)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(in: .capsule)
                            .backgroundStyle(.bar)
                            .transition(.scale)
                        }
                    }
                    .animation(.spring, value: view.isPinned)
                }
                .buttonStyle(.plain)
                .safeAreaPadding()
                .frame(height: 24, alignment: .center)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
    }
    
    struct DismissProgressBarModifier: ViewModifier {
        @Environment(Model.self) private var view
        @State private var isDismissed: Bool = false
        @State private var dismissProgress: Double = 1.0
        @State private var dismissTask: Task<Void, Never>?
        @State private var lastRecentEntryCount: Int = 0
        private let autoDismissInterval: TimeInterval = 6.0
        
        func body(content: Self.Content) -> some View {
            content
                .safeAreaInset(edge: .bottom) {
                    if !view.isPinned, !view.recentEntries.isEmpty {
                        DismissProgressBar(progress: dismissProgress) {
                            dismissLogs()
                        }
                        .onAppear {
                            self.lastRecentEntryCount = view.recentEntries.count
                            if shouldShowDismissBar { startDismissCountdown() }
                        }
                        .onChange(of: view.recentEntries.count, initial: true) { _, newValue in
                            if newValue > lastRecentEntryCount {
                                self.isDismissed = false
                                if !view.isPinned, !view.recentEntries.isEmpty { startDismissCountdown() }
                            }
                            if newValue == 0 {
                                dismissTask?.cancel()
                                self.dismissProgress = 1.0
                                self.isDismissed = false
                            }
                            self.lastRecentEntryCount = newValue
                        }
                        .task(id: view.isPinned) {
                            dismissTask?.cancel()
                            if view.isPinned {
                                self.dismissProgress = 1.0
                                self.isDismissed = false
                            } else if !view.recentEntries.isEmpty {
                                startDismissCountdown()
                            }
                        }
                    }
                }
        }
        
        private var shouldShowDismissBar: Bool {
            !view.isPinned && !view.recentEntries.isEmpty && !isDismissed
        }
        
        private func startDismissCountdown() {
            dismissTask?.cancel()
            self.isDismissed = false
            withAnimation(.none) { self.dismissProgress = 1.0 }
            self.dismissTask = Task { @MainActor in
                await Task.yield()
                withAnimation(.linear(duration: autoDismissInterval)) {
                    self.dismissProgress = 0.0
                }
                try? await Task.sleep(for: .seconds(autoDismissInterval))
                guard !Task.isCancelled else { return }
                dismissLogs()
            }
        }
        
        private func dismissLogs() {
            if view.isPinned {
                return
            }
            dismissTask?.cancel()
            withAnimation(.easeOut(duration: 0.15)) {
                self.isDismissed = true
                view.dismissOverlay()
            }
        }
        
        struct DismissProgressBar: View {
            var direction: UnitPoint = .center
            var progress: Double
            var onDismiss: () -> Void
            
            var body: some View {
                let clamped = min(1.0, max(0.0, progress))
                ZStack {
                    Capsule()
                        .fill(.white.opacity(0.25))
                    Capsule()
                        .fill(.white.opacity(0.75))
                        .scaleEffect(x: clamped, y: 1.0, anchor: direction)
                }
                .frame(height: 3)
                .clipShape(Capsule())
                .padding(.horizontal, 48)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onDismiss)
            }
        }
    }
}
