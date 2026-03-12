//
//  SettingsView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftData
import SwiftUI

#if canImport(BannerKit)
import BannerKit
#endif

#Preview(traits: .defaultData) {
    Color.clear.sheet(isPresented: .constant(true)) {
        SettingsView()
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Database.self) private var database
    @Environment(Library.self) private var library
    
    var body: some View {
        NavigationStack {
            List {
                Button("Delete Data Store", systemImage: "tash", role: .destructive) {
                    Task {
                        do {
                            try database.modelContainer.erase()
                            Banner.ok("Erase Successful") {
                                "Successfully erased `ModelContainer`."
                            }
                            try await Task.sleep(for: .seconds(2))
                            exit(EXIT_SUCCESS)
                        } catch {
                            Banner.error("Erase Failed") {
                                "Failed to erase `ModelContainer`: \(error)"
                            }
                        }
                    }
                }
                SeedSampleDataToggle()
                PreviewModeToggle()
                TestFeature()
                TabViewFeature()
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem {
                    Button("Close", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    struct SeedSampleDataToggle: View {
        @AppStorage("seed-sample-data") private var seedSampleData: Bool = true
        
        var body: some View {
            Section {
                VStack(alignment: .leading) {
                    Toggle(isOn: $seedSampleData) {
                        Label("Seed Sample Data", systemImage: "doc")
                    }
                    Divider()
                    Text("Seed the sample data for \(String(describing: DefaultSchema.self))")
                        .font(.caption)
                        .padding(4)
                }
            }
        }
    }
    
    struct PreviewModeToggle: View {
        @AppStorage("preview-mode") private var previewMode: Bool = false
        
        var body: some View {
            Section {
                VStack(alignment: .leading) {
                    Toggle(isOn: $previewMode) {
                        Label("Preview Mode", systemImage: "dot.scope.display")
                    }
                    Divider()
                    Text("Prepares the UI for screen capture (e.g. using a default date and time).")
                        .font(.caption)
                        .padding(4)
                }
            }
        }
    }
    
    struct TestFeature: View {
        @AppStorage("test-feature") private var testFeature: Bool = false
        
        var body: some View {
            Section {
                VStack(alignment: .leading) {
                    Toggle(isOn: $testFeature) {
                        Label("Test Feature", systemImage: "dot.scope.display")
                    }
                    Divider()
                    
                    DisclosureGroup {
                        Text("Constraint violations")
                    } label: {
                        Text("Force feature to run.")
                            .font(.caption)
       
                    }
                    .padding(4)
                }
            }
        }
    }
    
    struct TabViewFeature: View {
        @AppStorage("tab-view-mode") private var tabViewMode: TabViewMode = .default
        
        var body: some View {
            Section {
                VStack(alignment: .leading) {
                    Label("Tab View Mode", systemImage: "square")
                    Divider()
                    Text("Switch between SwiftUI TabView and custom TabView.")
                        .font(.caption)
                        .padding(4)
                    Picker("Select", selection: $tabViewMode) {
                        ForEach(TabViewMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                }
            }
        }
    }
}
