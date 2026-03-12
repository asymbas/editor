//
//  ContentView.swift
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
import TipKit

#if canImport(Shared)
import Shared
#endif

#Preview {
    ContentView()
}

struct ContentView: View {
    @Environment(\.configurator) private var configurator
    
    var body: some View {
        switch configurator.library {
        case let library?:
            DetailView()
                .predicateTreeOverlay()
                .dependencies(library)
                .transition(.blurReplace)
                .task { try? Tips.configure([.displayFrequency(.immediate)]) }
        case nil:
            SampleView()
                .transition(.scale)
        }
    }
}

// FIXME: SwiftUI's `TabView` is causing memory leaks.

struct DetailView: View {
    @AppStorage(.tabViewMode) private var mode: TabViewMode = .default
    
    var body: some View {
        switch mode {
        case .default: DefaultTabViewContainer()
        case .custom: CustomTabViewContainer()
        }
    }
    
    struct DefaultTabViewContainer: View {
        @AppStorage(.tabContainer) private var tab: TabContainer = .overview
        
        var body: some View {
            TabView(selection: $tab) {
                ForEach(TabContainer.allCases) { container in
                    container.tab
                }
            }
        }
    }
    
    struct CustomTabViewContainer: View {
        @Environment(Console.self) private var console
        @Environment(Observer.self) private var observer
        @AppStorage(.tabContainer) private var tab: TabContainer = .overview
        
        var body: some View {
            CustomTabView(selection: $tab) {
                ForEach(TabContainer.allCases) { tab in
                    ZStack {
                        switch tab {
                        case .overview:
                            DatabaseView()
                                .tabBadge(observer.violations.count)
                        case .console:
                            ConsoleView()
                                .tabBadge(console.alertCount)
                        case .editor:
                            TabContainer.EditorTabView()
                        case .test:
                            TabContainer.TestTabView()
                        case .more:
                            TabContainer.RouteTabView()
                        }
                    }
                    .tab(tab.title, systemImage: tab.systemImage, value: tab)
                }
            }
        }
    }
}

enum TabViewMode: String, CaseIterable, Identifiable {
    case `default`
    case custom
    
    var id: Self { self }
}

enum TabContainer: String, CaseIterable, Codable, Hashable, Identifiable {
    case overview
    case console
    case editor
    case test
    case more
    
    var id: Self { self }
    
    var title: String {
        rawValue.capitalized
    }
    
    var systemImage: String {
        switch self {
        case .overview: "grid"
        case .console: "terminal"
        case .editor: "keyboard.fill"
        case .test: "checkmark.circle.trianglebadge.exclamationmark"
        case .more: "ellipsis"
        }
    }
    
    @MainActor @TabContentBuilder<Self> var tab: some TabContent<Self> {
        switch self {
        case .overview:
            OverviewTab(title, systemImage: systemImage, value: self)
        case .console:
            ConsoleTab(title, systemImage: systemImage, value: self)
        case .editor:
            Tab(title, systemImage: systemImage, value: self) { EditorTabView() }
        case .test:
            Tab(title, systemImage: systemImage, value: self) { TestTabView() }
        case .more:
            Tab(title, systemImage: systemImage, value: self) { RouteTabView() }
        }
    }
    
    struct OverviewTab: TabContent {
        @Environment(Observer.self) private var delegate
        var title: String
        var systemImage: String
        var value: TabContainer
        
        init(_ title: String, systemImage: String, value: TabContainer) {
            self.title = title
            self.systemImage = systemImage
            self.value = value
        }
        
        var body: some TabContent<TabContainer> {
            Tab(title, systemImage: systemImage, value: value) {
                DatabaseView()
            }.badge(delegate.violations.count)
        }
    }
    
    struct ConsoleTab: TabContent {
        @Environment(Console.self) private var console
        var title: String
        var systemImage: String
        var value: TabContainer
        
        init(_ title: String, systemImage: String, value: TabContainer) {
            self.title = title
            self.systemImage = systemImage
            self.value = value
        }
        
        var body: some TabContent<TabContainer> {
            Tab("Console", systemImage: "terminal", value: .console) {
                ConsoleView()
            }
            .badge(console.alertCount)
        }
    }
    
    struct EditorTabView: View {
        @Environment(Database.self) private var database
        
        var body: some View {
            if let _ = self.database.stores.first?.value {
                EmptyView()
            }
        }
    }
    
    struct TestTabView: View {
        var body: some View {
            PredicateTestTabView()
        }
    }
    
    struct RouteTabView: View {
        @Environment(\.modelContext) private var modelContext
        @Environment(\.router) private var router
        @Environment(\.schema) private var schema
        @State private var path: NavigationPath = .init()
        @State private var showSettings: Bool = false
        @AppStorage(.tabContainer) private var tab: TabContainer = .overview
        @AppStorage(.route) private var route: String?
        
        var body: some View {
            @Bindable var router = self.router
            NavigationStack(path: $router.path) {
                List {
                    NavigationButton("Information", systemImage: "info.circle") {
                        InformationSectionView()
                    }
                    Section("General") {
                        ForEach(GeneralContainer.allCases) { container in
                            NavigationButton(container: container)
                        }
                    }
                    Section("References") {
                        ForEach(ReferencesContainer.allCases) { container in
                            NavigationButton(container: container)
                        }
                    }
                    Group {
                        Section("Static") {
                            ForEach(StaticContainer.allCases) { container in
                                NavigationButton(container: container)
                                    .badge("Test")
                            }
                        }
                        Section("SwiftData Features") {
                            ForEach(SwiftDataContainer.allCases) { container in
                                NavigationButton(container: container)
                            }
                        }
                        Section("DataStoreKit Features") {
                            ForEach(DataStoreKitContainer.allCases) { container in
                                NavigationButton(container: container)
                                    .isIncomplete(container.isIncomplete)
                            }
                        }
                    }
                    .disabled(schema != Schema(versionedSchema: DefaultSchema.self))
                }
                .link(to: GeneralContainer.self)
                .link(to: ReferencesContainer.self)
                .link(to: StaticContainer.self)
                .link(to: SwiftDataContainer.self)
                .link(to: DataStoreKitContainer.self)
                .navigationTitle("Menu")
                .toolbar {
                    ToolbarItem {
                        Button("Settings", systemImage: "gear") {
                            self.showSettings = true
                        }
                    }
                }
            }
            .restoreRouteOnTab(
                for: .more,
                selection: $tab,
                decoders: [
                    .container(GeneralContainer.self),
                    .container(ReferencesContainer.self),
                    .container(StaticContainer.self),
                    .container(SwiftDataContainer.self),
                    .container(DataStoreKitContainer.self)
                ]
            )
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}
