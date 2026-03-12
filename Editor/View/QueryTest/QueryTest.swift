//
//  QueryTest.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreRuntime
import DataStoreSupport
import SwiftData
import SwiftUI

extension EnvironmentValues {
    @Entry fileprivate var status: QueryRun.Status = .idle
    @Entry fileprivate var lastRun: QueryRun?
}

struct QueryTest<Model>: View where Model: PersistentModel {
    typealias FetchDescriptorBuilder = @Sendable () -> sending FetchDescriptor<Model>
    @DatabaseActor @Environment(\.schema) private var schema
    @DatabaseActor @State private var task: Task<Void, any Swift.Error>?
    @DatabaseActor private var fetchDescriptorBuilder: FetchDescriptorBuilder
    @DatabaseActor private var seed: SeedAction?
    @Environment(Observer.self) private var observer
    @Environment(\.autoRunOnAppear) private var autoRunOnAppear
    @Environment(\.modelContext) private var modelContext
    @Environment(\.resetBeforeRun) private var resetBeforeRun
    @State private var runs: [QueryRun] = []
    @State private var lastRun: QueryRun?
    @State private var status: QueryRun.Status = .idle
    @State private var isRunning: Bool = false
    @State private var showLatestTranslation: Bool = true
    nonisolated private var title: String
    nonisolated private var description: String?
    nonisolated private var expectations: QueryRun.Expectations
    
    init(
        _ title: String,
        description: String? = nil,
        expectations: QueryRun.Expectations = .init(),
        seed: SeedAction? = nil,
        descriptor: @escaping FetchDescriptorBuilder
    ) {
        self.title = title
        self.description = description
        self.expectations = expectations
        self.seed = seed
        self.fetchDescriptorBuilder = descriptor
    }
    
    init(
        _ title: String,
        description: String? = nil,
        expectations: QueryRun.Expectations.Rule...,
        seed: SeedAction? = nil,
        descriptor: @escaping FetchDescriptorBuilder
    ) {
        self.init(
            title,
            description: description,
            expectations: QueryRun.Expectations.build(expectations),
            seed: seed,
            descriptor: descriptor
        )
    }
    
    init(
        _ title: String,
        description: String? = nil,
        expectations: QueryRun.Expectations = .init(),
        @SeedBuilder build seed: @escaping @DatabaseActor () -> [SeedOperation],
        descriptor: @escaping FetchDescriptorBuilder
    ) {
        self.init(
            title,
            description: description,
            expectations: expectations,
            seed: QueryRun.seed(seed),
            descriptor: descriptor
        )
    }
    
    init(
        _ title: String,
        description: String? = nil,
        expectations: QueryRun.Expectations.Rule...,
        @SeedBuilder build seed: @escaping @DatabaseActor () -> [SeedOperation],
        descriptor: @escaping FetchDescriptorBuilder
    ) {
        self.init(
            title,
            description: description,
            expectations: QueryRun.Expectations.build(expectations),
            seed: QueryRun.seed(seed),
            descriptor: descriptor
        )
    }
    
    init(
        _ title: String,
        description: String? = nil,
        expectations: QueryRun.Expectations = .init(),
        seed: @autoclosure @escaping @DatabaseActor () -> [SeedOperation],
        descriptor: @escaping FetchDescriptorBuilder
    ) {
        self.init(
            title,
            description: description,
            expectations: expectations,
            seed: { context in try SeedExecutor.run(seed(), in: context) },
            descriptor: descriptor
        )
    }
    
    init(
        _ title: String,
        description: String? = nil,
        expectations: QueryRun.Expectations.Rule...,
        seed: @autoclosure @escaping @DatabaseActor () -> [SeedOperation],
        descriptor: @escaping FetchDescriptorBuilder
    ) {
        self.init(
            title,
            description: description,
            expectations: QueryRun.Expectations.build(expectations),
            seed: { context in try SeedExecutor.run(seed(), in: context) },
            descriptor: descriptor
        )
    }
    
    var body: some View {
        CardView {
            HeaderView(title: title, description: description)
            HStack(spacing: 10) {
                HStack {
                    RunButton(onRun: triggerRun)
                        .disabled(isRunning)
                    if expectations.hasAssertions {
                        ChipView("Assertions")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if !runs.isEmpty {
                    Button("Clear") {
                        runs.removeAll()
                        self.lastRun = nil
                        self.status = .idle
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
                Toggle(isOn: $showLatestTranslation) {
                    Image(systemName: "doc.text.magnifyingglass")
                }
                .toggleStyle(.button)
                .disabled(lastRun == nil)
            }
            if let lastRun = self.lastRun {
                AssertionsSectionView(checks: lastRun.checks)
                if showLatestTranslation {
                    LatestTranslationSectionView(run: lastRun)
                }
                if let error = lastRun.error {
                    ErrorView(error)
                }
            }
            if !runs.isEmpty {
                Divider()
                RunsSectionView(
                    runs: runs,
                    onSelect: { run in lastRun = run }
                )
            }
        }
        .environment(\.lastRun, lastRun)
        .environment(\.status, status)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.85),
            value: status
        )
        .task {
            if autoRunOnAppear {
                triggerRun()
            }
        }
    }
    
    private func triggerRun() {
        let modelContainer = self.modelContext.container
        Task { @DatabaseActor in
            await run(modelContainer: modelContainer)
        }
    }
    
    @DatabaseActor private func run(modelContainer: ModelContainer) async {
        guard !(await isRunning) && task == nil else {
            return
        }
        self.task?.cancel()
        let (translations, resetBeforeRun) = await MainActor.run {
            self.isRunning = true
            self.status = .running
            return (self.observer.translations, self.resetBeforeRun)
        }
        let descriptor = fetchDescriptorBuilder()
        let predicateDescription = descriptor.predicate.map { String(describing: $0) }
        let matchHash = predicateDescription?.hashValue
        let /*beforeCount*/ _ = translations.filter { $0.predicateHash == matchHash }.count
        self.task = Task(priority: .utility) { @DatabaseActor in
            defer {
                self.task?.cancel()
                self.task = nil
            }
            let startTime = Date()
            var run: QueryRun
            do {
                let modelContext = ModelContext(modelContainer)
                try await DatabaseActor.run {
                    if resetBeforeRun {
                        try resetAll(modelContext)
                    }
                    if let seed = self.seed {
                        try seed(modelContext)
                        try modelContext.save()
                    }
                }
                let descriptor = fetchDescriptorBuilder()
                let descriptorDescription = String(describing: descriptor)
                let predicateDescription = descriptor.predicate.map {
                    String(describing: $0)
                }
                let fetchedResult = try modelContext.fetch(descriptor)
                let captured = await Task {
                    await observer.nextTranslation(matchHash: matchHash)
                }.value
                let elapsedTime = Date().timeIntervalSince(startTime)
                run = QueryRun(
                    elapsed: elapsedTime,
                    count: fetchedResult.count,
                    error: nil,
                    sql: captured.sql,
                    placeholdersCount: captured.placeholdersCount,
                    bindingsCount: captured.bindingsCount,
                    descriptorDescription: descriptorDescription,
                    predicateDescription: predicateDescription,
                    tree: captured.tree
                )
            } catch {
                let captured = await Task {
                    await observer.nextTranslation(matchHash: matchHash)
                }.value
                let elapsedTime = Date().timeIntervalSince(startTime)
                run = QueryRun(
                    elapsed: elapsedTime,
                    count: 0,
                    error: error,
                    sql: captured.sql,
                    placeholdersCount: captured.placeholdersCount,
                    bindingsCount: captured.bindingsCount,
                    descriptorDescription: nil,
                    predicateDescription: nil,
                    tree: captured.tree
                )
            }
            run.status = await statusFor(run: &run)
            try await Task.sleep(for: .seconds(autoRunOnAppear ? Int.random(in: 0...3) : 0))
            await MainActor.run {
                runs.insert(run, at: 0)
                self.lastRun = run
                self.status = run.status
                self.isRunning = false
            }
        }
    }
    
    @concurrent
    nonisolated private func statusFor(run: inout QueryRun) async -> QueryRun.Status {
        run.checks = await buildChecks(for: run)
        if run.checks.contains(where: { !$0.passed }) {
            return .failure
        }
        if expectations.expectedCount != nil
            || expectations.expectedBindingsCount != nil
            || expectations.expectedPlaceholdersCount != nil
            || !expectations.sqlMustContain.isEmpty
            || !expectations.sqlMustNotContain.isEmpty
            || expectations.expectedError {
            return .success
        }
        if run.error != nil { return .failure }
        return .success
    }
    
    @concurrent
    nonisolated private func buildChecks(for run: QueryRun) async -> [QueryRun.Check] {
        var checks = [QueryRun.Check]()
        if expectations.expectedError {
            let passed = run.error != nil
            checks.append(.init(
                title: "Expected an error",
                description: passed
                ? "Got error: \(run.error?.localizedDescription ?? "")"
                : "No error was thrown",
                passed: passed
            ))
        } else {
            let passed = run.error == nil
            checks.append(.init(
                title: "No error thrown",
                description: passed ? nil : (run.error?.localizedDescription ?? ""),
                passed: passed
            ))
        }
        if let expectedCount = expectations.expectedCount {
            let passed = run.error == nil && run.count == expectedCount
            checks.append(.init(
                title: "Result count == \(expectedCount)",
                description: "Actual: \(run.count)",
                passed: passed
            ))
        }
        if let expectedBindingsCount = expectations.expectedBindingsCount {
            let actual = run.bindingsCount
            let passed = actual != nil && actual == expectedBindingsCount
            checks.append(.init(
                title: "Bindings count == \(expectedBindingsCount)",
                description: "Actual: \(actual.map(String.init) ?? "nil")",
                passed: passed
            ))
        }
        if let expectedPlaceholdersCount = expectations.expectedPlaceholdersCount {
            let actual = run.placeholdersCount
            let passed = actual != nil && actual == expectedPlaceholdersCount
            checks.append(.init(
                title: "Placeholders count == \(expectedPlaceholdersCount)",
                description: "Actual: \(actual.map(String.init) ?? "nil")",
                passed: passed
            ))
        }
        if let placeholdersCount = run.placeholdersCount,
           let bindingsCount = run.bindingsCount {
            checks.append(.init(
                title: "Placeholders == Bindings",
                description: "Placeholders: \(placeholdersCount), Bindings: \(bindingsCount)",
                passed: placeholdersCount == bindingsCount
            ))
        }
        if !expectations.sqlMustContain.isEmpty {
            let sql = run.sql ?? ""
            for needle in expectations.sqlMustContain {
                let passed = sql.contains(needle)
                checks.append(.init(
                    title: "SQL contains",
                    description: needle,
                    passed: passed
                ))
            }
        }
        if !expectations.sqlMustNotContain.isEmpty {
            let sql = run.sql ?? ""
            for needle in expectations.sqlMustNotContain {
                let passed = !sql.contains(needle)
                checks.append(.init(
                    title: "SQL does not contain",
                    description: needle,
                    passed: passed
                ))
            }
        }
        return checks
    }
    
    @DatabaseActor private func resetAll(_ modelContext: ModelContext) throws {
        for type in self.schema.types {
            let models = try modelContext.fetch(all: type)
            for model in models { modelContext.delete(model) }
        }
        try modelContext.save()
    }
    
    @DatabaseActor private func captureLatestTranslation(
        beforeCount: Int,
        matchHash: Int?
    ) async -> SQLPredicateTranslation {
        let translations = await self.observer.translations
        let matches = translations.filter { translation in
            guard let matchHash else {
                return true
            }
            if let hash = translation.predicateHash {
                return hash == matchHash
            }
            if let predicate = translation.predicateDescription {
                return predicate.hashValue == matchHash
            }
            return false
        }
        guard let latest = matches.last else {
            return .init(id: UUID())
        }
        if let sql = latest.sql {
            return .init(
                id: latest.id,
                predicateDescription: latest.predicateDescription,
                predicateHash: latest.predicateHash,
                sql: sql,
                placeholdersCount: latest.placeholdersCount
                ?? sql.filter { $0 == "?" }.count,
                bindingsCount: latest.bindingsCount,
                tree: latest.tree
            )
        }
        let node = latest.tree.path.last(where: { $0.title == "Generated SQL" })
        let sql = node?.content.first
        let placeholdersCount = parseIntPrefix(
            lines: node?.content ?? [],
            prefix: "Placeholders Count:"
        ) ?? sql.map { $0.filter { $0 == "?" }.count }
        let bindingsCount = parseIntPrefix(
            lines: node?.content ?? [],
            prefix: "Bindings Count:"
        ) ?? parseBindingsCountFallback(lines: node?.content ?? [])
        return .init(
            id: latest.id,
            predicateDescription: latest.predicateDescription,
            predicateHash: latest.predicateHash,
            sql: sql,
            placeholdersCount: placeholdersCount,
            bindingsCount: bindingsCount,
            tree: latest.tree
        )
        func parseIntPrefix(lines: [String], prefix: String) -> Int? {
            guard let line = lines.first(where: { $0.hasPrefix(prefix) }) else {
                return nil
            }
            return Int(line.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces))
        }
        func parseBindingsCountFallback(lines: [String]) -> Int? {
            guard let line = lines.first(where: { $0.hasPrefix("Bindings:") }) else {
                return nil
            }
            if line.contains("[]") { return 0 }
            return nil
        }
    }
    
    struct CardView<Content: View>: View {
        @Environment(\.status) private var status
        @ViewBuilder var content: Content
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: status.backgroundColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(status.color.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        }
    }
    
    struct HeaderView: View {
        @Environment(\.lastRun) private var lastRun
        @Environment(\.status) private var status
        var title: String
        var description: String?
        
        var body: some View {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey(title))
                        .font(.headline)
                        .foregroundStyle(lastRun == nil ? Color.primary : .white)
                        .blendMode(lastRun == nil ? .plusLighter : .plusDarker)
                    if let description = self.description {
                        Text(LocalizedStringKey(description))
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial)
                            .clipShape(.rect(cornerRadius: 16, style: .continuous))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                StatusBadge(status: status)
            }
        }
    }
    
    struct StatusBadge: View {
        var status: QueryRun.Status
        
        var body: some View {
            HStack(spacing: 10) {
                Circle()
                    .fill(status.color)
                    .frame(width: 10)
                Text(status.label)
                    .font(.caption)
                    .bold()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }
    
    struct RunButton: View {
        @Environment(\.status) private var status
        let onRun: @MainActor () -> Void
        
        var body: some View {
            Button(action: onRun) {
                Label {
                    Text(status == .running ? "Running..." : "Run")
                        .fontWeight(.semibold)
                } icon: {
                    if status == .running {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.fill")
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(.regularMaterial)
                .clipShape(Capsule())
                .lineLimit(1)
                .truncationMode(.tail)
            }
            .buttonStyle(.plain)
        }
    }
    
    struct ChipView: View {
        private var title: String
        
        init(_ title: String) {
            self.title = title
        }
        
        var body: some View {
            Text(LocalizedStringKey(title))
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.08))
                .clipShape(Capsule())
        }
    }
    
    struct ErrorView: View {
        private var error: any Swift.Error
        
        init(_ error: any Swift.Error) {
            self.error = error
        }
        
        var body: some View {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(error.localizedDescription)
            }
            .font(.footnote)
            .padding(8)
            .foregroundStyle(.red)
            .background(.red.opacity(0.1))
            .clipShape(.rect(cornerRadius: 8))
        }
    }
    
    struct SectionLabelStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .textCase(.uppercase)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    struct SectionContentStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(8)
                .background(Color.black.opacity(0.04))
                .clipShape(.rect(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.separator.opacity(0.1), lineWidth: 1)
                )
        }
    }
    
    struct SectionView<Content: View, Label: View>: View {
        private var label: Label
        private var content: Content
        
        init(
            @ViewBuilder content: () -> Content,
            @ViewBuilder label: () -> Label
        ) {
            self.label = label()
            self.content = content()
        }
        
        init(
            @ViewBuilder content: () -> Content,
            @ViewBuilder label: (SectionLabelStyle) -> Label
        ) {
            self.label = label(SectionLabelStyle())
            self.content = content()
        }
        
        init(_ titleKey: LocalizedStringKey, @ViewBuilder content: () -> Content)
        where Label == ModifiedContent<Text, QueryTest<Model>.SectionLabelStyle> {
            self.label = { Text(titleKey).modifier(SectionLabelStyle()) }()
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                label
                    .modifier(SectionLabelStyle())
                VStack {
                    content.textSelection(.enabled)
                }
                .modifier(SectionContentStyle())
            }
        }
    }
    
    struct PredicateSectionView<Content: View, Label: View>: View {
        private var label: Label
        private var content: Content
        
        init(_ titleKey: LocalizedStringKey, description: String)
        where Content == Text, Label == Text {
            self.label = { Text(titleKey) }()
            self.content = {
                Text(description).font(.system(.footnote, design: .monospaced))
            }()
        }
        
        var body: some View {
            SectionView {
                ScrollView(.horizontal) {
                    content
                }
                .scrollClipDisabled()
                .scrollIndicatorsFlash(onAppear: true)
                .scrollIndicators(.hidden)
            } label: {
                label
            }
        }
    }
    
    struct AssertionsSectionView: View {
        var checks: [QueryRun.Check]
        
        var body: some View {
            SectionView("Assertions") {
                ForEach(checks) { check in
                    CheckRowView(check: check)
                }
            }
        }
        
        struct CheckRowView: View {
            var check: QueryRun.Check
            
            var body: some View {
                HStack(spacing: 8) {
                    Image(systemName: check.passed
                          ? "checkmark.circle.fill"
                          : "xmark.octagon.fill"
                    )
                    .imageScale(.large)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, check.passed ? .green : .red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(check.title)
                            .font(.footnote.weight(.semibold))
                        if let description = self.check.description, !description.isEmpty {
                            Text(description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(8)
                .background(.black.opacity(0.04))
                .clipShape(.rect(cornerRadius: 10))
            }
        }
    }
    
    struct LatestTranslationSectionView: View {
        var run: QueryRun
        
        var body: some View {
            if let descriptorDescription = self.run.descriptorDescription {
                PredicateSectionView("Descriptor", description: .init(descriptorDescription))
            }
            if let predicateDescription = self.run.predicateDescription {
                PredicateSectionView("Predicate", description: .init(predicateDescription))
            }
            if let sql = self.run.sql {
                PredicateSectionView("SQL", description: .init(sql))
            }
            if run.placeholdersCount != nil || run.bindingsCount != nil {
                HStack(spacing: 10) {
                    if let count = self.run.placeholdersCount {
                        ChipView("Placeholders: \(count)")
                    }
                    if let count = self.run.bindingsCount {
                        ChipView("Bindings: \(count)")
                    }
                    Spacer()
                }
            }
            if let tree = self.run.tree {
                PredicateTreeView(tree: tree)
            } else {
                Text("No predicate tree captured for this run.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    struct PredicateTreeView: View {
        @State private var treeFilter: String = ""
        @State private var showTree: Bool = false
        var tree: PredicateTree
        
        var body: some View {
            SectionView {
                VStack {
                    if showTree {
                        TextField(
                            "Filter Nodes...",
                            text: $treeFilter,
                            prompt: Text("Filter Nodes...")
                                .fontWeight(.regular)
                                .foregroundStyle(.white.opacity(0.9))
                        )
                        .textFieldStyle(.plain)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled()
                        .fontWeight(.semibold)
                        .frame(height: 30)
                        .padding(.horizontal)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.ultraThinMaterial.opacity(0.5))
                        )
                        .colorScheme(.dark)
                        .overlay(alignment: .trailing) {
                            Image(systemName: "magnifyingglass")
                                .padding()
                        }
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(filteredNodes(tree: tree), id: \.self) { node in
                                    PredicateTreeNodeView(node: node)
                                }
                            }
                        }
                        .scrollClipDisabled()
                    } else {
                        Text("\(tree.path.count) nodes")
                    }
                }
                .font(.caption)
                .transition(.blurReplace.combined(with: .scale(0.0, anchor: .top)))
            } label: { style in
                HStack {
                    Text("Predicate Tree").modifier(style)
                    Spacer()
                    Button(showTree ? "Hide" : "Show") {
                        withAnimation { showTree.toggle() }
                    }
                    .buttonStyle(.borderless)
                }
            }
            .animation(.spring(duration: 0.25), value: showTree)
        }
        
        private func filteredNodes(tree: PredicateTree) -> [PredicateTree.Node] {
            let nodes = self.treeFilter.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !nodes.isEmpty else { return tree.path }
            return tree.path.filter { node in
                if node
                    .title
                    .localizedCaseInsensitiveContains(nodes) {
                    return true
                }
                if node
                    .content
                    .joined(separator: "\n")
                    .localizedCaseInsensitiveContains(nodes) {
                    return true
                }
                if String(describing: node.expression)
                    .localizedCaseInsensitiveContains(nodes) {
                    return true
                }
                return false
            }
        }
        
        struct PredicateTreeNodeView: View {
            var node: PredicateTree.Node
            
            var body: some View {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(node.title)
                            .font(.footnote.weight(.semibold))
                        Spacer()
                        Text("lvl \(node.level)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(node.content, id: \.self) { line in
                        Text(line)
                            .textSelection(.enabled)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(10)
                .background(.black.opacity(0.04))
                .clipShape(.rect(cornerRadius: 12))
                .padding(.leading, CGFloat(max(0, node.level - 1)) * 10)
            }
        }
    }
    
    struct RunsSectionView: View {
        var runs: [QueryRun]
        let onSelect: (QueryRun) -> Void
        
        var body: some View {
            SectionView("Runs") {
                ForEach(runs) { run in
                    Button {
                        onSelect(run)
                    } label: {
                        RunRowView(run: run)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        
        struct RunRowView: View {
            var run: QueryRun
            
            var body: some View {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(run.count) items")
                            .font(.subheadline.weight(.medium))
                        Text(run.date, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(run.elapsed.formatted(.number.precision(.fractionLength(3))))s")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(run.status.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(run.status.color)
                    }
                }
                .modifier(SectionContentStyle())
            }
        }
    }
}
