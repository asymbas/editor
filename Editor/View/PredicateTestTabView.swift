//
//  PredicateTestTabView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreCore
import DataStoreKit
import DataStoreSupport
import SwiftData
import SwiftUI

#Preview(traits: .defaultData) {
    PredicateTestTabView()
}

extension String {
    nonisolated static var predicateTestAutoRun: Self {
        "predicate-test-auto-run"
    }
}

struct PredicateTestTabView: View {
    @AppStorage(.predicateTestAutoRun) private var autoRunOnAppear: Bool = false
    
    var body: some View {
        NavigationStack {
            TestContainer {
                Group {
                    NavigationLink(
                        "Fetch Descriptors",
                        value: FetchDescriptorsList.identifier
                    )
                    NavigationLink(
                        "Standard Predicate Expressions",
                        value: StandardPredicateExpressionsList.identifier
                    )
                    NavigationLink(
                        "Attribute Coverage Tests",
                        value: AttributeCoverageTests.identifier
                    )
                    NavigationLink(
                        "Relationship Coverage Tests",
                        value: RelationshipCoverageTests.identifier
                    )
                }
                .buttonStyle(.borderedProminent)
                SectionView("Raw Value") {
                    RawValuePredicateTests()
                }
                SectionView("Dictionary") {
                    PredicateTestStack<SupportedCollectionType>(
                        "Dictionary Predicate",
                        resetBeforeRun: true,
                        predicate: #Predicate { $0.stringDictionary["key"] == "value" }
                    ) {
                        PredicateVariant(
                            "Success",
                            expectations: .expectedCount(1), .noError,
                            seed: QueryRun.seed {
                                SupportedCollectionType(stringDictionary: ["key": "value"])
                            }
                        )
                        PredicateVariant(
                            "Count Mismatch",
                            description: "Failure",
                            expectations: .expectedCount(2), .noError,
                            seed: QueryRun.seed {
                                SupportedCollectionType(stringDictionary: ["key": "value"])
                            }
                        )
                        PredicateVariant(
                            "Seed and Predicate Mismatch",
                            description: "Failure",
                            expectations: .expectedCount(1), .noError,
                            seed: QueryRun.seed {
                                SupportedCollectionType(stringDictionary: ["key": "nope"])
                            }
                        )
                    }
                    PredicateTest<SupportedCollectionType>(
                        "Dictionary Predicate (Random Failure)",
                        expectations: .expectedCount(Int.random(in: 1...2)),
                        seed: QueryRun.seed {
                            .insert(SupportedCollectionType(stringDictionary: ["key": "value"]))
                        },
                        predicate: #Predicate {
                            $0.stringDictionary["key"] == "value"
                        }
                    )
                }
            }
            .id(autoRunOnAppear)
            .environment(\.autoRunOnAppear, autoRunOnAppear)
            .navigationTitle("Predicate Tests")
            .navigationDestination(for: String.self) { value in
                Group {
                    switch value {
                    case FetchDescriptorsList.identifier:
                        FetchDescriptorsList()
                    case StandardPredicateExpressionsList.identifier:
                        StandardPredicateExpressionsList()
                    case AttributeCoverageTests.identifier:
                        AttributeCoverageTests()
                    case RelationshipCoverageTests.identifier:
                        RelationshipCoverageTests()
                    default:
                        EmptyView()
                    }
                }
                .environment(\.autoRunOnAppear, autoRunOnAppear)
            }
            .toolbar {
                ToolbarItem {
                    Toggle("Auto Run", isOn: $autoRunOnAppear)
                }
                ToolbarItem {
                    PredicateTreeButton()
                }
            }
        }
    }
    
    struct SectionView<Content>: View where Content: View {
        private var title: LocalizedStringKey
        private var description: LocalizedStringKey?
        private var content: Content
        
        init(
            _ title: LocalizedStringKey,
            description: LocalizedStringKey? = nil,
            @ViewBuilder content: () -> Content
        ) {
            self.title = title
            self.description = description
            self.content = content()
        }
        
        var body: some View {
            Section {
                content
            } header: {
                HStack {
                    VStack { Divider() }
                    Text(title)
                        .font(.title2.weight(.bold))
                    VStack { Divider() }
                }
                if let description = self.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    struct TestContainer<Content>: View where Content: View {
        @State private var scrollPosition: ScrollPosition = .init(idType: UUID.self)
        @ViewBuilder var content: Content
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    content
                }
            }
            .contentMargins(16, for: .scrollContent)
            .scrollPosition($scrollPosition)
            .scrollContentBackground(.visible)
        }
    }
    
    struct RawValuePredicateTests: View {
        // TODO: Use `seed` instead of `seedAction` when Swift Playground uses Swift 6.2.
        #if swift(>=6.2)
        @DatabaseActor @SeedBuilder private var seed: [SeedOperation] {
            RawValueModel(
                color: .red,
                shape: .rectangle
            )
            RawValueModel(
                color: .green,
                colors: [.blue],
                shape: .square,
                shapes: [.circle, .triangle]
            )
        }
        private var seedAction: SeedAction { QueryRun.seed(seed) }
        #else
        private var seedAction: SeedAction {
            QueryRun.seed {
                RawValueModel(color: .red, shape: .rectangle)
                RawValueModel(
                    color: .green,
                    colors: [.blue],
                    shape: .square,
                    shapes: [.circle, .triangle]
                )
            }
        }
        #endif
        
        var body: some View {
            let red = RawValueModel.Color.red
            let green = RawValueModel.Color.green
            let blue = RawValueModel.Color.blue
            let rectangle = RawValueModel.Shape.rectangle
            let square = RawValueModel.Shape.square
            let circle = RawValueModel.Shape.circle
            let triangle = RawValueModel.Shape.triangle
            PredicateTest<RawValueModel>(
                "Enum Raw Value",
                description: "Use enum cases with `#Predicate`",
                expectations: .expectedCount(1),
                seed: seedAction,
                predicate: #Predicate { $0.color == red }
            )
            PredicateTest<RawValueModel>(
                "Enum Raw Value in Collection",
                description: "Use enum cases in collections with `#Predicate`",
                expectations: .expectedCount(1),
                seed: seedAction,
                predicate: #Predicate {
                    $0.color == green &&
                    $0.colors.contains(blue)
                }
            )
            PredicateTest<RawValueModel>(
                "Struct Raw Value",
                description: "Use struct constants with `#Predicate`",
                expectations: .expectedCount(1),
                seed: seedAction,
                predicate: #Predicate { $0.shape == rectangle }
            )
            PredicateTest<RawValueModel>(
                "Struct Raw Value in Collection",
                description: "Use struct constants in collections with `#Predicate`",
                expectations: .expectedCount(1),
                seed: seedAction,
                predicate: #Predicate {
                    $0.shape == square &&
                    $0.shapes.contains(circle) &&
                    $0.shapes.contains(triangle)
                }
            )
        }
    }
    
    struct StandardPredicateExpressionsList: View {
        static var identifier: String { "\(self)" }
        
        var body: some View {
            #if swift(>=6.2)
            TestContainer {
                CountPredicateTests()
            }
            #else
            EmptyView()
            #endif
        }
        
        struct CountPredicateTests: View {
            private var seed: SeedAction {
                QueryRun.seed {
                    let cluster = Cluster(id: "cluster", name: "Cluster")
                    for index in 0..<100 {
                        Membership(
                            user: User(id: "user-\(index)", name: "User \(index)"),
                            group: cluster
                        )
                    }
                    cluster
                }
            }
            
            var body: some View {
                PredicateTest<Cluster>(
                    "Count `==`",
                    expectations: .expectedCount(1),
                    seed: seed,
                    predicate: #Predicate { $0.memberships.count == 100 }
                )
                PredicateTest<Cluster>(
                    "Count `>`",
                    expectations: .expectedCount(1),
                    seed: seed,
                    predicate: #Predicate { $0.memberships.count > 99 }
                )
                PredicateTest<Cluster>(
                    "Count `>=`",
                    expectations: .expectedCount(1),
                    seed: seed,
                    predicate: #Predicate { $0.memberships.count >= 99 }
                )
                PredicateTest<Cluster>(
                    "Count `<`",
                    expectations: .expectedCount(1),
                    seed: seed,
                    predicate: #Predicate { $0.memberships.count < 101 }
                )
                PredicateTest<Cluster>(
                    "Count `<=`",
                    expectations: .expectedCount(1),
                    seed: seed,
                    predicate: #Predicate { $0.memberships.count <= 100 }
                )
                Divider()
                PredicateTest<Cluster>(
                    "Count `>` `false`",
                    expectations: .expectedCount(0),
                    seed: seed,
                    predicate: #Predicate { $0.memberships.count > 100 }
                )
                PredicateTest<Cluster>(
                    "Count `<` `false`",
                    expectations: .expectedCount(0),
                    seed: seed,
                    predicate: #Predicate { $0.memberships.count < 100 }
                )
            }
        }
    }
    
    struct FetchDescriptorsList: View {
        static var identifier: String { "\(self)" }
        @Environment(Observer.self) private var observer
        @Environment(\.schema) private var schema
        @State private var configuration: DatabaseConfiguration?
        @State private var modelContainer: ModelContainer?
        
        var body: some View {
            #if swift(>=6.2)
            TestContainer {
                if let modelContainer = self.modelContainer {
                    GeneralTests()
                        .modelContainer(modelContainer)
                } else {
                    ProgressView()
                        .task {
                            let configuration = DatabaseConfiguration(
                                transient: (),
                                options: [.disableSnapshotCaching, .disablePredicateCaching],
                                attachment: observer
                            )
                            let modelContainer = try! ModelContainer(
                                for: schema,
                                configurations: [configuration]
                            )
                            self.configuration = configuration
                            self.modelContainer = modelContainer
                        }
                }
            }
            #else
            EmptyView()
            #endif
        }
        
        struct GeneralTests: View {
            #if swift(>=6.2)
            @DatabaseActor @SeedBuilder private var seed: [SeedOperation] {
                User()
                let user = User(
                    id: "user-anferne-pineda",
                    name: "Anferne Pineda"
                )
                let profile = Profile(
                    id: "profile-anferne-pineda",
                    preferredName: "Anferne",
                    user: user
                )
                user; profile
            }
            private var seedAction: SeedAction { QueryRun.seed(seed) }
            #else
            private var seedAction: SeedAction {
                QueryRun.seed {
                    User()
                    let user = User(
                        id: "user-anferne-pineda",
                        name: "Anferne Pineda"
                    )
                    let profile = Profile(
                        id: "profile-anferne-pineda",
                        preferredName: "Anferne",
                        user: user
                    )
                    user; profile
                }
            }
            #endif
            
            var body: some View {
                QueryTest<User>(
                    "Fetch Limit / Fetch Offset",
                    description: "Test",
                    expectations:
                            .expectedCount(1),
                    .sqlMustContain("LIMIT 1"),
                    .sqlMustContain("OFFSET 1"),
                    seed: seedAction
                ) {
                    var descriptor = FetchDescriptor<User>()
                    descriptor.fetchLimit = 10
                    descriptor.fetchOffset = 1
                    descriptor.sortBy = [.init(\.date.added, order: .forward)]
                    return descriptor
                }
                QueryTest<User>(
                    "`SortDescriptor` and `SortOrder`",
                    description: "Test",
                    expectations: .sqlMustContain("ORDER BY"),
                    seed: seedAction
                ) {
                    var descriptor = FetchDescriptor<User>()
                    descriptor.sortBy = [
                        .init(\.date.added, order: .forward),
                        .init(\.name, order: .forward),
                        .init(\.id, order: .reverse)
                    ]
                    return descriptor
                }
                Divider()
                QueryTest<User>(
                    "SortDescriptor Relationship Failure",
                    description: "Test",
                    expectations: .noError,
                    seed: seedAction
                ) {
                    var descriptor = FetchDescriptor(predicate: #Predicate<User> { user in
                        user.id == "user-anferne-pineda"
                    })
                    descriptor.fetchLimit = 1
                    descriptor.sortBy = [
                        .init(\.date.added, order: .forward),
                        .init(\.name, order: .forward),
                        .init(\.profile?.displayName, order: .reverse)
                    ]
                    return descriptor
                }
                QueryTest<User>(
                    "Fetch Limit",
                    description: "Test",
                    expectations: .expectedCount(1),
                    seed: seedAction
                ) {
                    var descriptor = FetchDescriptor(predicate: #Predicate<User> { user in
                        user.id == "user-anferne-pineda"
                    })
                    descriptor.fetchLimit = 1
                    descriptor.sortBy = [
                        .init(\.date.added, order: .reverse)]
                    return descriptor
                }
            }
        }
    }
}

struct AttributeCoverageTests: View {
    static var identifier: String { "\(self)" }
    
    private var scalarSeed: SeedAction {
        QueryRun.seed {
            .insert(
                SupportedScalarType(
                    id: "scalar",
                    bool: true,
                    integer: 5,
                    double: 9.0,
                    string: "Hello, World!"
                )
            )
        }
    }
    
    private var collectionSeed: SeedAction {
        QueryRun.seed {
            .insert(
                SupportedCollectionType(
                    id: "collection",
                    integerArray: [1, 2, 3, 4, 5, 9],
                    stringArray: ["alpha", "beta", "Hello, World!"],
                    stringDictionary: ["key": "value"]
                )
            )
        }
    }
    
    private var optionalMixedSeed: SeedAction {
        QueryRun.seed {
            SeedOperation
                .insert(SupportedOptionalScalarType(id: "optional-value", integer: 5, string: "Hello, World!"))
        }
    }
    
    private var optionalNonNilSeed: SeedAction {
        QueryRun.seed {
            .insert(SupportedOptionalScalarType(id: "optional-only", integer: 5, string: "Hello, World!"))
        }
    }
    
    var body: some View {
        let orderedSame = ComparisonResult.orderedSame
        let needle = "World"
        let fallback = "fallback"
        let prefix = [1, 2, 3]
        let plusOne = #Expression<SupportedScalarType, Int> { value in
            value.integer + 1
        }
        let innerPredicate = #Predicate<SupportedCollectionType> { value in
            value.integerArray.contains(9)
        }
        List {
            Section("Scalar Types") {
                PredicateTest<SupportedScalarType>(
                    "Arithmetic",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.integer + 1 == 6
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "UnaryMinus",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        -value.integer == -5
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "IntDivision",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.integer / 2 == 2
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "IntRemainder",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.integer % 2 == 1
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "FloatDivision",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.double / 2.0 == 4.5
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "Comparison",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.integer >= 5
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "Equal",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.integer == 5
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "NotEqual",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.integer != 0
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "Conjunction",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.integer == 5 && value.bool == true
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "Disjunction",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.integer == 0 || value.integer == 5
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "Negation",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        !(value.integer == 0)
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "Conditional",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.bool ? (value.integer == 5) : (value.integer == -1)
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "KeyPath",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.string == "Hello, World!"
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "CollectionContainsCollection",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.string.contains(needle)
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "StringLocalizedStandardContains",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.string.localizedStandardContains(needle)
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "StringCaseInsensitiveCompare",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.string.caseInsensitiveCompare("hello, world!") == orderedSame
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "StringLocalizedCompare",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.string.localizedCompare("Hello, World!") == orderedSame
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "StringContainsRegex",
                    description: "Feature is not supported",
                    expectations: .expectedCount(1), .expectedError,
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.string.contains(/World/)
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "Range",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        (0..<10).contains(value.integer)
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "ClosedRange",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        (1...10).contains(value.integer)
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "RangeExpressionContains",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        (1...10).contains(value.integer)
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "ExpressionEvaluate",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        plusOne.evaluate(value) == 6
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "TypeCheck",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        (value as Any) is SupportedScalarType
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "ConditionalCast",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        ((value as Any) as? SupportedScalarType) != nil
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "ForceCast",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        ((value as Any) as! SupportedScalarType).id == "scalar"
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "Value",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { _ in
                        true
                    }
                )
                PredicateTest<SupportedScalarType>(
                    "Variable",
                    expectations: .expectedCount(1),
                    seed: scalarSeed,
                    predicate: #Predicate { value in
                        value.id == "scalar"
                    }
                )
            }
            Section("Collection Types") {
                PredicateTest<SupportedCollectionType>(
                    "SequenceContains",
                    expectations: .expectedCount(1),
                    seed: collectionSeed,
                    predicate: #Predicate { value in
                        value.integerArray.contains(9)
                    }
                )
                PredicateTest<SupportedCollectionType>(
                    "SequenceContainsWhere",
                    expectations: .expectedCount(1),
                    seed: collectionSeed,
                    predicate: #Predicate { value in
                        value.integerArray.contains { element in
                            element > 8
                        }
                    }
                )
                PredicateTest<SupportedCollectionType>(
                    "SequenceAllSatisfy",
                    expectations: .expectedCount(1),
                    seed: collectionSeed,
                    predicate: #Predicate { value in
                        value.integerArray.allSatisfy { element in
                            element > 0
                        }
                    }
                )
                PredicateTest<SupportedCollectionType>(
                    "Filter",
                    expectations: .expectedCount(1),
                    seed: collectionSeed,
                    predicate: #Predicate { value in
                        value.integerArray.filter { element in
                            element > 3
                        }.count == 3
                    }
                )
                PredicateTest<SupportedCollectionType>(
                    "SequenceMinimum",
                    expectations: .expectedCount(1),
                    seed: collectionSeed,
                    predicate: #Predicate { value in
                        value.integerArray.min() == 1
                    }
                )
                PredicateTest<SupportedCollectionType>(
                    "SequenceMaximum",
                    expectations: .expectedCount(1),
                    seed: collectionSeed,
                    predicate: #Predicate { value in
                        value.integerArray.max() == 9
                    }
                )
                PredicateTest<SupportedCollectionType>(
                    "SequenceStartsWith",
                    expectations: .expectedCount(1),
                    seed: collectionSeed,
                    predicate: #Predicate { value in
                        value.integerArray.starts(with: prefix)
                    }
                )
                PredicateTest<SupportedCollectionType>(
                    "CollectionIndexSubscript",
                    expectations: .expectedCount(1),
                    seed: collectionSeed,
                    predicate: #Predicate { value in
                        value.integerArray[0] == 1
                    }
                )
                PredicateTest<SupportedCollectionType>(
                    "CollectionRangeSubscript",
                    expectations: .expectedCount(1),
                    seed: collectionSeed,
                    predicate: #Predicate { value in
                        value.integerArray[1..<3].contains(2)
                    }
                )
                PredicateTest<SupportedCollectionType>(
                    "DictionaryKeySubscript",
                    expectations: .expectedCount(1),
                    seed: collectionSeed,
                    predicate: #Predicate { value in
                        value.stringDictionary["key"] == "value"
                    }
                )
                PredicateTest<SupportedCollectionType>(
                    "DictionaryKeyDefaultValueSubscript",
                    expectations: .expectedCount(1),
                    seed: collectionSeed,
                    predicate: #Predicate { value in
                        value.stringDictionary["missing", default: fallback] == fallback
                    }
                )
                PredicateTest<SupportedCollectionType>(
                    "PredicateEvaluate",
                    expectations: .expectedCount(1),
                    seed: collectionSeed,
                    predicate: #Predicate { value in
                        innerPredicate.evaluate(value)
                    }
                )
            }
            Section("Optional Scalar Types") {
                PredicateTest<SupportedOptionalScalarType>(
                    "NilLiteral",
                    expectations: .expectedCount(1),
                    seed: optionalMixedSeed,
                    predicate: #Predicate { value in
                        value.string == nil
                    }
                )
                PredicateTest<SupportedOptionalScalarType>(
                    "NilCoalesce",
                    expectations: .expectedCount(1),
                    seed: optionalMixedSeed,
                    predicate: #Predicate { value in
                        (value.string ?? fallback) == fallback
                    }
                )
                PredicateTest<SupportedOptionalScalarType>(
                    "OptionalFlatMap",
                    expectations: .expectedCount(1),
                    seed: optionalMixedSeed,
                    predicate: #Predicate { value in
                        value.string.flatMap { text in
                            text.contains(needle)
                        } == true
                    }
                )
                PredicateTest<SupportedOptionalScalarType>(
                    "ForcedUnwrap",
                    expectations: .expectedCount(1),
                    seed: optionalNonNilSeed,
                    predicate: #Predicate { value in
                        value.string!.contains(needle)
                    }
                )
            }
        }
    }
}

struct RelationshipCoverageTests: View {
    static var identifier: String { "\(self)" }
    
    private var sampleSeed: SeedAction {
        QueryRun.seed {
            let businessUser = User(id: "user-business", name: "Anferne")
            let noProfileUser = User(id: "user-no-profile", name: "NoProfile")
            let businessProfile = Profile(
                id: "profile-business",
                preferredName: "Anferne",
                status: [.active],
                representation: .business,
                user: businessUser
            )
            businessUser.profile = businessProfile
            let tagKey = Tag(key: nil, value: "key")
            let tagOther = Tag(key: nil, value: "other")
            let helloPost = Post(
                id: "post-hello",
                title: "Hello, World!",
                content: "seed",
                author: businessUser,
                tags: [tagKey]
            )
            let replyPost = Post(
                id: "post-reply",
                title: "Reply",
                content: "seed",
                author: businessUser,
                original: helloPost,
                tags: [tagOther]
            )
            businessUser.posts = [helloPost, replyPost]
            helloPost.nested = [replyPost]
            let cluster = Cluster(id: "cluster", name: "Cluster")
            let membershipBusiness = Membership(
                id: "membership-business",
                role: "member",
                user: businessUser,
                group: cluster
            )
            let membershipNoProfile = Membership(
                id: "membership-no-profile",
                role: "member",
                user: noProfileUser,
                group: cluster
            )
            cluster.memberships = [membershipBusiness, membershipNoProfile]
            let bookmark = Bookmark(id: "bookmark", user: businessUser, post: helloPost)
            let activityWithUser = Activity(
                id: "activity-user",
                events: ["default": .now],
                message: "with user",
                user: businessUser
            )
            let activityNilUser = Activity(
                id: "activity-nil",
                events: ["default": .now],
                message: "nil user",
                user: nil
            )
            businessUser
            noProfileUser
            businessProfile
            tagKey
            tagOther
            helloPost
            replyPost
            cluster
            membershipBusiness
            membershipNoProfile
            bookmark
            activityWithUser
            activityNilUser
        }
    }
    
    private var cycleSeed: SeedAction {
        QueryRun.seed {
            let lhs = CardinalityTestDependencyCycle.AssociatedEntity.LHS(id: "lhs")
            let rhs = CardinalityTestDependencyCycle.AssociatedEntity.RHS(id: "rhs")
            let entity = CardinalityTestDependencyCycle.AssociatedEntity(
                id: "intermediary",
                lhs: lhs,
                rhs: rhs
            )
            lhs.intermediary = [entity]
            rhs.intermediary = [entity]
            lhs; rhs; entity
        }
    }
    
    var body: some View {
        let representation = Profile.Representation.business
        let activeStatus = Profile.Status.active
        let needle = "World"
        let fallback = "fallback"
        let authorIdentifier = #Expression<Post, String> { post in
            post.author.id
        }
        let postIsHello = #Predicate<Post> { post in
            post.title == "Hello, World!"
        }
        List {
            Section("Optional To-One Relationships") {
                PredicateTest<User>(
                    "KeyPath (Relationship Join)",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { user in
                        user.profile?.representation == representation
                    }
                )
                PredicateTest<User>(
                    "OptionalFlatMap (Optional To-One Relationshiphip)",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { user in
                        user.profile.flatMap { profile in
                            profile.representation == representation
                        } == true
                    }
                )
                PredicateTest<User>(
                    "ForcedUnwrap (Optional To-One Relationship)",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { user in
                        user.profile!.preferredName == "Anferne"
                    }
                )
                PredicateTest<User>(
                    "NilCoalesce (Optional Chain)",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { user in
                        (user.profile?.preferredName ?? fallback) == "Anferne"
                    }
                )
                PredicateTest<User>(
                    "NilLiteral (Optional Relationship Is `nil`)",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { user in
                        user.profile == nil
                    }
                )
                PredicateTest<User>(
                    "Conditional (Relationship Presence)",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { user in
                        user.profile != nil ? (user.profile!.representation == representation) : false
                    }
                )
            }
            Section("To-Many Relationships") {
                PredicateTest<User>(
                    "SequenceContainsWhere (To-Many Relationship)",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { user in
                        user.posts.contains { post in
                            post.title == "Hello, World!"
                        }
                    }
                )
                PredicateTest<User>(
                    "Conjunction + Deep Relationship Traversal",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { user in
                        user.id == "user-business" &&
                        user.posts.contains { post in
                            post.title == "Hello, World!" &&
                            post.tags.contains { tag in
                                tag.value == "key"
                            }
                        }
                    }
                )
                PredicateTest<User>(
                    "Filter (to-many relationship)",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { user in
                        user.posts.filter { post in
                            post.title.contains(needle)
                        }.count == 1
                    }
                )
                PredicateTest<User>(
                    "Arithmetic + IntDivision + IntRemainder (Relationship Count)",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { user in
                        (user.posts.count + 1) == 3 &&
                        (user.posts.count / 2) == 1 &&
                        (user.posts.count % 2) == 0
                    }
                )
                PredicateTest<User>(
                    "Range/ClosedRange/RangeExpressionContains (Relationship Count)",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { user in
                        (0..<10).contains(user.posts.count) &&
                        (1...3).contains(user.posts.count)
                    }
                )
                PredicateTest<User>(
                    "SequenceContains",
                    description: "Captured value through relationship",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { user in
                        user.profile!.status.contains(activeStatus)
                    }
                )
                PredicateTest<Tag>(
                    "Inverse Relationship Traversal",
                    description: "`Tag.posts, Post.author, Author.profile",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { tag in
                        tag.value == "key" &&
                        tag.posts.contains { post in
                            post.author.profile?.representation == representation
                        }
                    }
                )
            }
            Section("Self-Referencing Relationships") {
                PredicateTest<Post>(
                    "Self relationship (NilLiteral + ForcedUnwrap)",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { post in
                        post.id == "post-reply" &&
                        post.original != nil &&
                        post.original!.id == "post-hello"
                    }
                )
            }
            Section("Other") {
                PredicateTest<Bookmark>(
                    "Multi-join (Bookmark.user + Bookmark.post.author)",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { bookmark in
                        bookmark.user.id == "user-business" &&
                        bookmark.post.author.id == "user-business"
                    }
                )
                PredicateTest<Activity>(
                    "Optional relationship + Negation",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { activity in
                        activity.user == nil && !(activity.message == "with user")
                    }
                )
                PredicateTest<Post>(
                    "ExpressionEvaluate (relationship keypath via expression)",
                    expectations: .expectedCount(2),
                    seed: sampleSeed,
                    predicate: #Predicate { post in
                        authorIdentifier.evaluate(post) == "user-business"
                    }
                )
                PredicateTest<User>(
                    "PredicateEvaluate (evaluate inner predicate on related values)",
                    expectations: .expectedCount(1),
                    seed: sampleSeed,
                    predicate: #Predicate { user in
                        user.posts.contains { post in
                            postIsHello.evaluate(post)
                        }
                    }
                )
                PredicateTest<CardinalityTestDependencyCycle.AssociatedEntity.LHS>(
                    "CollectionIndexSubscript (relationship array)",
                    expectations: .expectedCount(1),
                    seed: cycleSeed,
                    predicate: #Predicate { lhs in
                        lhs.intermediary[0].rhs.id == "rhs"
                    }
                )
                PredicateTest<CardinalityTestDependencyCycle.AssociatedEntity.LHS>(
                    "CollectionRangeSubscript (relationship array slice)",
                    expectations: .expectedCount(1),
                    seed: cycleSeed,
                    predicate: #Predicate { lhs in
                        lhs.intermediary[0..<1].contains { entity in
                            entity.id == "intermediary"
                        }
                    }
                )
                PredicateTest<CardinalityTestDependencyCycle.AssociatedEntity.LHS>(
                    "Comparison (relationship count)",
                    expectations: .expectedCount(1),
                    seed: cycleSeed,
                    predicate: #Predicate { lhs in
                        lhs.intermediary.count >= 1
                    }
                )
            }
        }
    }
}
