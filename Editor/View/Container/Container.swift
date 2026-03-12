//
//  Container.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import DataStoreSupport
import SwiftData
import SwiftUI

enum GeneralContainer: String, ContainerProtocol {
    static var key: String { "general" }
    case store
    case schema
    case workbench
    
    var title: String {
        rawValue.capitalized
    }
    
    var details: String {
        switch self {
        case .store:
            "The `DatabaseConfiguration` and `DatabaseStore` used to create `Database`."
        case .schema:
            "The `Schema` instance provided to the `DatabaseConfiguration`."
        case .workbench:
            "Review scenarios, migration plans, delete rules, and other objects in the data store observer."
        }
    }
    
    var systemImage: String {
        switch self {
        case .store: "doc"
        case .schema: "cylinder"
        case .workbench: "hammer"
        }
    }
    
    var route: some View {
        switch self {
        case .store: StoreView()
        case .schema: SchemaView()
        case .workbench: SchemaWorkbenchView()
        }
    }
}

enum ReferencesContainer: String, ContainerProtocol {
    static var key: String { "references" }
    case graphCanvas = "graph canvas"
    case graphTest = "graph test"
    case graphList = "graph list"
    
    var title: String {
        rawValue.capitalized
    }
    
    var details: String {
        switch self {
        case .graphCanvas:
            "An interactive visualization of the relationships between models using the `ReferenceGraph`."
        case .graphTest:
            "Load models into the `ReferenceGraph` and run tests on the graph."
        case .graphList:
            "View a list of incoming/outgoing relationships for a model using the `ReferenceGraph`."
        }
    }
    
    var systemImage: String {
        switch self {
        case .graphCanvas: "point.3.connected.trianglepath.dotted"
        case .graphTest: "graph.2d"
        case .graphList: "circle.dotted.and.circle"
        }
    }
    
    var route: some View {
        switch self {
        case .graphCanvas: ReferenceGraphView()
        case .graphTest: ReferenceGraphTestView()
        case .graphList: ReferenceGraphListView()
        }
    }
}

enum StaticContainer: String, ContainerProtocol {
    static var key: String { "static" }
    case internalSchemaManagement = "internal schema management"
    case storeOperations = "store operations"
    case fetchAggregate = "fetch aggregate"
    
    var title: String {
        rawValue.capitalized
    }
    
    var details: String {
        switch self {
        case .internalSchemaManagement:
            "Manage all \(DefaultSchema.models.count) models in `DefaultSchema`."
        case .storeOperations:
            "Run preset store operations on internal models."
        case .fetchAggregate:
            "A view for inspecting or mutating the models fetched from the `ModelContext`."
        }
    }
    
    var systemImage: String {
        switch self {
        case .internalSchemaManagement: "square.stack.3d.up"
        case .storeOperations: "play"
        case .fetchAggregate: "list.bullet.below.rectangle"
        }
    }
    
    var route: some View {
        switch self {
        case .internalSchemaManagement: SchemaModelsDetailView()
        case .storeOperations: StoreOperationsDetailView()
        case .fetchAggregate: FetchModelsDetailView()
        }
    }
    
    struct SchemaModelsDetailView: View {
        var body: some View {
            EmptyView()
        }
    }
    
    struct StoreOperationsDetailView: View {
        var body: some View {
            StoreOperationsView()
        }
    }
    
    struct FetchModelsDetailView: View {
        var body: some View {
            FetchAggregateViewer()
        }
    }
}

enum SwiftDataContainer: String, ContainerProtocol {
    static var key: String { "feature" }
    case modelContextTest = "modelcontext test"
    case editingStateLifecycle = "editingstate lifecycle"
    case historyTracking = "history tracking"
    case sync = "sync"
    case fetchModels = "fetch models"
    case fetchProperties = "fetch properties"
    case prefetchRelationships = "prefetch relationships"
    case constraintTest = "constraint test"
    case externalStorage = "external storage"
    case issues = "issues"
    
    var title: String {
        switch self {
        case .modelContextTest:
            "ModelContext Test"
        case .editingStateLifecycle:
            "EditingState Lifecycle"
        default:
            rawValue.capitalized
        }
    }
    
    var details: String {
        switch self {
        case .modelContextTest:
            "Test `ModelContext` APIs with the custom data store."
        case .editingStateLifecycle:
            "`ModelContext` and `EditingState` introspection experiments."
        case .historyTracking:
            "View the persistent history tracking and transactions."
        case .sync:
            "Try syncing with `\(DatabaseHistoryToken.self).self` with local one-way syncing and CloudKit syncing."
        case .fetchModels:
            "Fetch models into memory. Uses `fetch(_:)` and the new `preloadedFetch(_:)`."
        case .fetchProperties:
            "Fetch models with specific properties, similar to using `SELECT` on columns."
        case .prefetchRelationships:
            "Fetch models and prefetch relationships. This feature includes related models with the same fetch request."
        case .constraintTest:
            "Test relationship constraints, such as delete rules and cardinality behaviors."
        case .externalStorage:
            "Test attribute properties that are stored in external storage."
        case .issues:
            "Deterministic issues that have not been resolved."
        }
    }
    
    var systemImage: String {
        switch self {
        case .modelContextTest: "circle.dotted.circle"
        case .editingStateLifecycle: "sleep.circle"
        case .historyTracking: "clock"
        case .sync: "arrow.trianglehead.2.clockwise.rotate.90"
        case .fetchModels: "magnifyingglass"
        case .fetchProperties: "square.text.square"
        case .prefetchRelationships: "heart.text.square"
        case .constraintTest: "trash"
        case .externalStorage: "externaldrive.connected.to.line.below"
        case .issues: "flag"
        }
    }
    
    var route: some View {
        switch self {
        case .modelContextTest: ModelContextTestDetailView()
        case .editingStateLifecycle: EditingStateLifecycleTestDetailView()
        case .historyTracking: HistoryTrackingTestView()
        case .sync: SyncTestView()
        case .fetchModels: FetchModelsView()
        case .fetchProperties: FetchPropertiesView()
        case .prefetchRelationships: PrefetchRelationshipsView()
        case .externalStorage: ExternalStorageTestView()
        case .constraintTest: ConstraintTestView()
        case .issues: IssueListView()
        }
    }
    
    struct ModelContextTestDetailView: View {
        var body: some View {
            ModelContextTestView()
                .withTransientModelContainer(of: [Entity.self])
        }
    }
    
    struct EditingStateLifecycleTestDetailView: View {
        @Environment(Database.self) private var database
        
        var body: some View {
            EditingStateLifecycleHarness(container: database.modelContainer)
        }
    }
    
    struct IssueListView: View {
        var body: some View {
            EmptyView()
        }
    }
}

enum DataStoreKitContainer: String, ContainerProtocol {
    static var key: String { "demo" }
    case snapshotSerialization = "snapshot serialization"
    case snapshotMutation = "snapshot mutation"
    case mergeData = "merge data"
    case rollbackDiscard = "rollback discard"
    case storeTransfer = "store transfer"
    case customBackingData = "custom backing data"
    case fetchPreload = "fetch preload"
    case resultBuilder = "result builder"
    
    var title: String {
        rawValue.capitalized
    }
    
    var details: String {
        switch self {
        case .snapshotSerialization:
            "Use `DatabaseSnapshot` to serialize and deserialize model instances or turn them into value types."
        case .snapshotMutation:
            "Use getters and setters on `DatabaseSnapshot`."
        case .mergeData:
            "Merge a snapshot to or from a model and vice versa."
        case .rollbackDiscard:
            "Create a snapshot of a `PersistentModel`, then use it to rollback or discard editing changes."
        case .storeTransfer:
            "Send a `DataStoreSnapshot` from one store to another that shares the same identifier."
        case .customBackingData:
            "Experimenting `CustomBackingData` that conforms to `BackingData<Model>`."
        case .fetchPreload: 
            "Use the `@Fetch` property wrapper or preloading APIs."
        case .resultBuilder:
            "Shows the SQL statement produced by the `SQLBuilder` result builder."
        }
    }
    
    var systemImage: String {
        switch self {
        case .snapshotSerialization: "camera.viewfinder"
        case .snapshotMutation: "arrow.up.arrow.down"
        case .mergeData: "arrow.trianglehead.merge"
        case .rollbackDiscard: "arrow.2.circlepath.circle"
        case .storeTransfer: "cylinder"
        case .customBackingData: "document.viewfinder"
        case .fetchPreload: "star"
        case .resultBuilder: "equal.circle"
        }
    }
    
    var route: some View {
        switch self {
        case .snapshotSerialization: CodableDemoDetailView()
        case .snapshotMutation: SnapshotMutationDemoView()
        case .mergeData: MergeDataDemoView()
        case .rollbackDiscard: RollbackDiscardDemoView()
        case .storeTransfer: StoreTransferDemoView()
        case .customBackingData: CustomBackingDataDemoView()
        case .fetchPreload: FetchPreloadDemoView()
        case .resultBuilder: ResultBuilderView()
        }
    }
    
    var isIncomplete: Bool {
        switch self {
        case
                .snapshotMutation,
                .rollbackDiscard,
                .customBackingData: true
        default: false
        }
    }
    
    struct CodableDemoDetailView: View {
        var body: some View {
            CodableDemoView()
                .safeAreaPadding()
        }
    }
}
