//
//  FeatureSchema.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftData

struct FeatureSchema: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [
            SchemaConstraintModel.self,
            SchemaAttributeOptionModel.self,
            SchemaRelationshipOptionModel.self,
            SerialModel.self,
            RawValueModel.self
        ]
    }
    
    static var versionIdentifier: Schema.Version {
        .init(0, 0, 0)
    }
    
    static func seed(
        into modelContext: ModelContext,
        isolation: isolated Actor = #isolation
    ) async throws {
        let serialModel = SerialModel()
        serialModel.id = "serial"
        serialModel.name = "Serial"
        serialModel.redirect = "Redirect-Target"
        modelContext.insert(serialModel)
        let externalPayload = Data("external-storage-payload".utf8)
        let attributeTest1 = SchemaAttributeOptionModel(
            id: "external-storage-add",
            externalData: externalPayload
        )
        let attributeTest2 = SchemaAttributeOptionModel(
            id: "external-storage-remove",
            externalData: nil
        )
        modelContext.insert(attributeTest1)
        modelContext.insert(attributeTest2)
        let rawValueModel = RawValueModel(
            id: "raw-value-model",
            color: .red,
            colors: [.red, .green, .blue],
            shape: .rectangle,
            shapes: [.rectangle],
            style: .fill
        )
        if false {
            let constraintModel_0 = SchemaConstraintModel(title: "a", body: "0")
            modelContext.insert(constraintModel_0)
            try? modelContext.save()
            let constraintModel_1 = SchemaConstraintModel(title: "a", body: "0")
            modelContext.insert(constraintModel_1)
            try? modelContext.save()
        }
    }
}

@Model class SchemaConstraintModel {
    #Unique<SchemaConstraintModel>([\.title, \.body])
    
    @Attribute(.unique) var id: String
    @Attribute var title: String
    @Attribute var body: String
    
    init(
        id: String = UUID().uuidString,
        title: String,
        body: String
    ) {
        self.id = id
        self.title = title
        self.body = body
    }
}

@Model class SchemaAttributeOptionModel {
    @Attribute(.unique) var id: String
    @Attribute(.externalStorage) var externalData: Data?
    
    init(
        id: String = UUID().uuidString,
        externalData: Data?
    ) {
        self.id = id
        self.externalData = externalData
    }
}

@Model class SchemaRelationshipOptionModel {
    @Attribute(.unique) var id: String
    
    init(id: String = UUID().uuidString) {
        self.id = id
    }
}

/// A model that conforms to `Codable` and `PredicateCodableKeyPathProviding`.
///
/// - Uses `PredicateCodableKeyPathProviding` to supply key paths to SwiftData.
/// - `redirect` swaps its key path to point to `name`.
@Model final class SerialModel: Codable, PredicateCodableKeyPathProviding {
    @Attribute(.unique) var id: String
    @Attribute var name: String
    @Attribute var redirect: String
    
    init(
        id: String = UUID().uuidString,
        name: String = randomName(length: Int.random(in: 4...8)),
        redirect: String = ""
    ) {
        self.id = id
        self.name = name
        self.redirect = redirect
    }
    
    enum CodingKeys: String, CaseIterable, CodingKey {
        case id
        case name
        case redirect
    }
    
    /// Inherited from `Decodable.init(from:)`.
    required convenience init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.redirect = try container.decode(String.self, forKey: .redirect)
    }
    
    /// Inherited from `Encodable.encode(to:)`.
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(redirect, forKey: .redirect)
    }
    
    /// Inherited from `PredicateCodableKeyPathProviding.predicateCodableKeyPaths`.
    static let predicateCodableKeyPaths: [String: any PartialKeyPath<SerialModel> & Sendable] = {
        var dictionary = [String: any PartialKeyPath<SerialModel> & Sendable]()
        for key in CodingKeys.allCases {
            switch key {
            case .id: dictionary[key.rawValue] = \Self.id
            case .name: dictionary[key.rawValue] = \Self.name
            case .redirect: dictionary[key.rawValue] = \Self.name
            }
        }
        return dictionary
    }()
}

@Model class RawValueModel {
    @Attribute(.unique) var id: String
    @Attribute var color: Color
    @Attribute var colors: Set<Color>
    @Attribute var shape: Shape
    @Attribute var shapes: Set<Shape>
    @Attribute var style: Style
    
    init(
        id: String = UUID().uuidString,
        color: Color = .red,
        colors: Set<Color> = [],
        shape: Shape = .rectangle,
        shapes: Set<Shape> = [],
        style: Style = []
    ) {
        self.id = id
        self.color = color
        self.colors = colors
        self.shape = shape
        self.shapes = shapes
        self.style = style
    }
    
    enum Color: String, CaseIterable, Codable, Equatable, Hashable {
        case red
        case green
        case blue
    }
    
    struct Shape: CaseIterable, Codable, Equatable, Hashable, RawRepresentable {
        static let allCases: Set<Self> = [.rectangle, .square, .circle, .triangle]
        static let rectangle: Self = .init(rawValue: 0)
        static let square: Self = .init(rawValue: 1)
        static let circle: Self = .init(rawValue: 2)
        static let triangle: Self = .init(rawValue: 3)
        let rawValue: UInt
        
        init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
    }
    
    struct Style: CaseIterable, Codable, OptionSet {
        static let allCases: [Self] = [.fill, .stroke]
        static let fill: Self = .init(rawValue: 0)
        static let stroke: Self = .init(rawValue: 1)
        let rawValue: Int32
        
        init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
    }
}
