//
//  PreviewModifier.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftData
import SwiftUI

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var defaultData: Self = .modifier(DefaultData())
}

struct DefaultData: PreviewModifier {
    static func makeSharedContext() async throws -> Library {
        return Library(configuration: .default)
    }
    
    func body(content: Content, context: Library) -> some View {
        content.dependencies(context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var sampleData: Self = .modifier(SampleData())
}

struct SampleData: PreviewModifier {
    static func makeSharedContext() async throws -> Library {
        let library = Library(configuration: .transient)
        let modelContainer = library.database.modelContainer
        try await seedSampleData(into: modelContainer.mainContext)
        try modelContainer.mainContext.save()
        return library
    }
    
    func body(content: Content, context: Library) -> some View {
        content.dependencies(context)
    }
}
