//
//  SampleSchema.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftData

struct SampleSchema: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [
            User.self,
            Profile.self,
            Post.self,
            Bookmark.self,
            Tag.self,
            Cluster.self,
            Membership.self,
            Activity.self
        ]
    }
    
    static var versionIdentifier: Schema.Version {
        .init(0, 0, 0)
    }
    
    static func seed(
        into modelContext: ModelContext,
        isolation: isolated Actor = #isolation
    ) async throws {
        let tagSample = Tag(key: nil, value: "sample")
        let tagLibrary = Tag(key: "package", value: "library")
        let tagSwift = Tag(key: "topic", value: "swift")
        let tagSwiftData = Tag(key: "topic", value: "swiftdata")
        let tagSwiftUI = Tag(key: "topic", value: "swiftui")
        modelContext.insert(tagSample)
        modelContext.insert(tagLibrary)
        modelContext.insert(tagSwift)
        modelContext.insert(tagSwiftData)
        modelContext.insert(tagSwiftUI)
        let anferne = User(id: nil, name: "Anferne Pineda")
        let asymbas = User(id: nil, name: "Asymbas Inc.")
        let entity = User(id: nil, name: "Entity")
        let john = User(id: nil, name: "John Doe")
        let jane = User(id: nil, name: "Jane Doe")
        let anferneProfile = Profile(
            id: nil,
            preferredName: "anfernepineda",
            representation: .personal,
            user: anferne
        )
    anferneProfile.context = "personal"
        let asymbasProfile = Profile(
            id: nil,
            preferredName: "Asymbas",
            representation: .business,
            user: asymbas
        )
        asymbasProfile.context = "business"
        let entityProfile = Profile(
            id: nil,
            preferredName: "_",
            representation: nil,
            user: entity
        )
        entityProfile.context = "test"
        let johnProfile = Profile(
            id: nil,
            preferredName: "John D.",
            representation: nil,
            user: john
        )
        johnProfile.context = "male"
        let janeProfile = Profile(
            id: nil,
            preferredName: "Jane D.",
            representation: nil,
            user: jane
        )
        janeProfile.context = "female"
        anferne.profile = anferneProfile
        asymbas.profile = asymbasProfile
        entity.profile = entityProfile
        john.profile = johnProfile
        jane.profile = janeProfile
        modelContext.insert(anferne)
        modelContext.insert(asymbas)
        modelContext.insert(entity)
        modelContext.insert(john)
        modelContext.insert(jane)
        modelContext.insert(anferneProfile)
        modelContext.insert(asymbasProfile)
        modelContext.insert(entityProfile)
        modelContext.insert(johnProfile)
        modelContext.insert(janeProfile)
        let post1 = Post(
            id: "post-001",
            title: "Introduction",
            content: "Hello, world.",
            author: anferne
        )
        post1.tags = [tagSample]
        #if false
        var generator = RandomTextGenerator(configuration: .init(
            domain: .general,
            seed: 123
        ))
        let body = generator.text(targetCharacterCount: 200)
        #endif
        let content = ["a", "b", "c"]
        let post2 = Post(
            id: "post-002",
            title: "DataStoreKit",
            content: content.randomElement()!,
            author: asymbas
        )
        post2.tags = [tagLibrary, tagSwift]
        let post3 = Post(
            id: "post-003",
            title: "Swift, SwiftData, SwiftUI",
            content: content.randomElement()!,
            author: asymbas
        )
        post3.tags = [tagLibrary, tagSwift, tagSwiftData, tagSwiftUI]
        modelContext.insert(post1)
        modelContext.insert(post2)
        modelContext.insert(post3)
        let comment2 = Post(
            id: "comment-001",
            category: .comment,
            content: "asymbas/datastorekit",
            author: anferne,
            original: post1
        )
        let comment1 = Post(
            id: "comment-002",
            category: .comment,
            content: ".",
            author: entity,
            original: post2
        )
        let comment3 = Post(
            id: "comment-003",
            category: .comment,
            content: "...",
            author: anferne,
            original: post2
        )
        let comment4 = Post(
            id: "comment-004",
            category: .comment,
            content: "...",
            author: john,
            original: post2
        )
        let comment5 = Post(
            id: "comment-005",
            category: .comment,
            content: "...",
            author: jane,
            original: post2
        )
        modelContext.insert(comment1)
        modelContext.insert(comment2)
        modelContext.insert(comment3)
        modelContext.insert(comment4)
        modelContext.insert(comment5)
        let `default` = Cluster(id: "default", name: "Default")
        let unknown = Cluster(id: "unknown", name: "Unknown")
        modelContext.insert(`default`)
        modelContext.insert(unknown)
        let membership1 = Membership(
            id: "membership-001",
            role: "creator",
            date: makeDate(),
            user: anferne,
            group: `default`
        )
        let membership2 =  Membership(
            id: "membership-002",
            role: "author",
            date: makeDate(),
            user: asymbas,
            group: `default`
        )
        let membership3 = Membership(
            id: "membership-003",
            role: "member",
            date: makeDate(),
            user: entity,
            group: unknown
        )
        let membership4 = Membership(
            id: "membership-004",
            role: "member",
            date: makeDate(),
            user: john,
            group: unknown
        )
        let membership5 = Membership(
            id: "membership-005",
            role: "member",
            date: makeDate(),
            user: jane,
            group: unknown
        )
        modelContext.insert(membership1)
        modelContext.insert(membership2)
        modelContext.insert(membership3)
        modelContext.insert(membership4)
        modelContext.insert(membership5)
        let log1 = Activity(
            id: "log-001",
            events: ["start": makeDate(year: 2025, month: 5, day: 1, hour: 0, minute: 0)],
            message: "Alpha",
            user: asymbas
        )
        let log2 = Activity(
            id: "log-002",
            events: ["action": makeDate(year: 2025, month: 12, day: .random(in: 1...31))],
            message: "Beta",
            user: asymbas
        )
        let log3 = Activity(
            id: "log-003",
            events: ["action": makeDate(year: 2025, month: 12, day: .random(in: 1...31))],
            message: "Gamma",
            user: asymbas
        )
        let log4 = Activity(
            id: "log-004",
            events: ["action": makeDate(year: 2025, month: 12, day: .random(in: 1...31))],
            message: "Delta",
            user: asymbas
        )
        let log5 = Activity(
            id: "log-005",
            events: ["action": makeDate(year: 2025, month: 12, day: .random(in: 1...31))],
            message: "Epsilon",
            user: asymbas
        )
        modelContext.insert(log1)
        modelContext.insert(log2)
        modelContext.insert(log3)
        modelContext.insert(log4)
        modelContext.insert(log5)
        if true {
            let tag = Tag(key: "merge", value: "unit")
            modelContext.insert(tag)
            try modelContext.save()
            let post = Post(
                id: "any",
                author: .init(id: "identifier", name: "identity"),
                tags: [tag]
            )
            modelContext.insert(post)
            try modelContext.save()
        }
    }
}

@Model class User {
    #Index<User>([\.id, \.profile])
    #Unique<User>([\.id, \.profile])
    
    @Attribute(.unique, .preserveValueOnDeletion) var id: String
    @Attribute var date: DateMetadata
    @Attribute var name: String
    
    @Relationship(deleteRule: .cascade, inverse: \Profile.user)
    var profile: Profile?
    
    @Relationship(deleteRule: .cascade)
    var posts: [Post] = []
    
    @Relationship(deleteRule: .cascade)
    var groupMemberships: [Membership] = []
    
    init(
        id: String? = UUID().uuidString,
        date: DateMetadata = .init(),
        name: String = randomName(length: Int.random(in: 4...8)),
        profile: Profile? = nil
    ) {
        self.id = id ?? makeID(Self.self, name)
        self.date = date
        self.name = name
        self.profile = profile
    }
}

@Model class Profile {
    @Attribute(.unique, .preserveValueOnDeletion) var id: String
    @Attribute var preferredName: String?
    @Attribute var representation: Representation
    @Attribute var status: Set<Status>
    @Attribute var context: String?
    @Attribute(.externalStorage) var avatar: Data?
    
    @Relationship(.unique)
    var user: User
    
    init(
        id: String? = UUID().uuidString,
        preferredName: String? = nil,
        status: Set<Status> = [.active],
        representation: Representation? = nil,
        user: User
    ) {
        self.id = id ?? makeID(Self.self, user.name)
        self.preferredName = preferredName
        self.status = status
        self.representation = representation ?? .personal
        self.user = user
    }
    
    var displayName: String {
        preferredName ?? user.name
    }
    
    struct Status: Codable, Hashable, RawRepresentable {
        static let active: Self = .init(rawValue: 1)
        static let banned: Self = .init(rawValue: 2)
        let rawValue: UInt8
    }
    
    enum Representation: UInt8, CaseIterable, Codable {
        case personal
        case business
    }
}

@Model class Post {
    @Attribute(.unique, .preserveValueOnDeletion) var id: String
    @Attribute var date: DateMetadata
    @Attribute var category: Category
    @Attribute var title: String
    @Attribute var content: String
    @Attribute var viewCount: Int = 0
    @Attribute var metadata: [String: String]?
    
    @Relationship(inverse: \User.posts)
    var author: User
    
    @Relationship(inverse: \Post.nested)
    var original: Post?
    
    @Relationship(deleteRule: .cascade)
    var nested: [Post] = []
    
    @Relationship(deleteRule: .nullify)
    var tags: [Tag] = []
    
    init(
        id: String? = UUID().uuidString,
        date: DateMetadata = .init(),
        category: Category = .post,
        title: String = randomName(length: .random(in: 3...9)),
        content: String = randomName(length: .random(in: 3...9)),
        author: User,
        original: Post? = nil,
        nested: [Post] = [],
        tags: [Tag] = []
    ) {
        self.id = id ?? makeID(Self.self, author.name, UUID().uuidString)
        self.date = date
        self.category = category
        self.title = title
        self.content = content
        self.author = author
        self.original = original
        self.nested = nested
        self.tags = tags
    }
    
    enum Category: String, CaseIterable, Codable {
        case post
        case comment
    }
}

@Model class Bookmark {
    @Attribute(.unique) var id: String
    
    @Relationship
    var user: User
    
    @Relationship
    var post: Post
    
    init(
        id: String? = UUID().uuidString,
        user: User,
        post: Post
    ) {
        self.id = id ?? makeID(Self.self, user.name, post.author.name, post.id)
        self.user = user
        self.post = post
    }
}

@Model class Tag {
    #Unique<Tag>([\.key, \.value])
    
    @Attribute(.preserveValueOnDeletion) var key: String?
    @Attribute(.preserveValueOnDeletion) var value: String
    
    @Relationship(inverse: \Post.tags)
    var posts: [Post] = []
    
    init(
        key: String? = nil,
        value: String
    ) {
        self.key = key
        self.value = value
    }
}

@Model class Cluster {
    @Attribute(.unique) var id: String
    @Attribute var name: String
    
    @Relationship
    var posts: [Post] = []
    
    @Relationship(minimumModelCount: 1)
    var memberships: [Membership] = []
    
    init(
        id: String? = UUID().uuidString,
        name: String = randomName(length: 5)
    ) {
        self.id = id ?? makeID(Self.self, name)
        self.name = name
    }
}

@Model class Membership {
    @Attribute(.unique, .preserveValueOnDeletion) var id: String
    @Attribute var role: String
    @Attribute var date: Date
    
    @Relationship(inverse: \User.groupMemberships)
    var user: User
    
    @Relationship(inverse: \Cluster.memberships)
    var group: Cluster
    
    init(
        id: String? = UUID().uuidString,
        role: String = "member",
        date: Date = .now,
        user: User,
        group: Cluster
    ) {
        self.id = id ?? makeID(Self.self, user.name, group.name)
        self.role = role
        self.date = date
        self.user = user
        self.group = group
    }
}

@Model class Activity {
    @Attribute(.unique, .preserveValueOnDeletion) var id: String
    @Attribute var events: [String: Date]
    @Attribute var message: String
    
    @Relationship(deleteRule: .nullify)
    var user: User?
    
    init(
        id: String? = UUID().uuidString,
        events: [String: Date]? = nil,
        message: String,
        user: User? = nil
    ) {
        self.id = id ?? makeID(Self.self, UUID().uuidString)
        self.events = ["default": .now].merging(
            events ?? [:],
            uniquingKeysWith: { _, new in
                new
            })
        self.message = message
        self.user = user
    }
}
