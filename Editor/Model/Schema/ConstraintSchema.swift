//
//  ConstraintSchema.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftData

struct ConstraintSchema: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [
            DeleteRuleCascadeParent.self,
            DeleteRuleCascadeChild.self,
            DeleteRuleNullifyParent.self,
            DeleteRuleNullifyChild.self,
            DeleteRuleDenyParent.self,
            DeleteRuleDenyChild.self,
            CardinalityParent.self,
            CardinalityChild.self
        ]
    }
    
    static var versionIdentifier: Schema.Version {
        .init(0, 0, 0)
    }
}

@Model final class DeleteRuleCascadeParent {
    @Attribute(.unique) var id: String
    @Attribute var name: String
    
    @Relationship(
        deleteRule: .cascade,
        inverse: \DeleteRuleCascadeChild.parent
    ) var children: [DeleteRuleCascadeChild] = []
    
    init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
    }
}

@Model final class DeleteRuleCascadeChild {
    @Attribute(.unique) var id: String
    @Attribute var name: String
    
    @Relationship
    var parent: DeleteRuleCascadeParent?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        parent: DeleteRuleCascadeParent? = nil
    ) {
        self.id = id
        self.name = name
        self.parent = parent
    }
}

@Model final class DeleteRuleNullifyParent {
    @Attribute(.unique) var id: String
    @Attribute var name: String
    
    @Relationship(
        deleteRule: .nullify,
        inverse: \DeleteRuleNullifyChild.parent
    ) var children: [DeleteRuleNullifyChild] = []
    
    init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
    }
}

@Model final class DeleteRuleNullifyChild {
    @Attribute(.unique) var id: String
    @Attribute var name: String
    
    @Relationship
    var parent: DeleteRuleNullifyParent?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        parent: DeleteRuleNullifyParent? = nil
    ) {
        self.id = id
        self.name = name
        self.parent = parent
    }
}

@Model final class DeleteRuleDenyParent {
    @Attribute(.unique) var id: String
    @Attribute var name: String
    
    @Relationship(
        deleteRule: .deny,
        inverse: \DeleteRuleDenyChild.parent
    ) var children: [DeleteRuleDenyChild] = []
    
    init(
        id: String = UUID().uuidString,
        name: String
    ) {
        self.id = id
        self.name = name
    }
}

@Model final class DeleteRuleDenyChild {
    @Attribute(.unique) var id: String
    @Attribute var name: String
    
    @Relationship
    var parent: DeleteRuleDenyParent
    
    init(
        id: String = UUID().uuidString,
        name: String,
        parent: DeleteRuleDenyParent
    ) {
        self.id = id
        self.name = name
        self.parent = parent
    }
}

@Model final class CardinalityParent {
    @Attribute(.unique) var id: String
    @Attribute var name: String
    
    @Relationship(
        minimumModelCount: 3,
        maximumModelCount: 5,
        inverse: \CardinalityChild.parent
    ) var children: [CardinalityChild]
    
    init(
        id: String = UUID().uuidString,
        name: String,
        children: [CardinalityChild]
    ) {
        self.id = id
        self.name = name
        self.children = children
    }
}

@Model final class CardinalityChild {
    @Attribute(.unique) var id: String
    @Attribute var name: String
    
    @Relationship
    var parent: CardinalityParent?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        parent: CardinalityParent? = nil
    ) {
        self.id = id
        self.name = name
        self.parent = parent
    }
}
