//
//  StoreOperationsView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import Logging
import SwiftData

struct StoreOperationsView: View {
    @Environment(\.schema) private var schema
    @Environment(\.modelContext) private var modelContext
    @State private var approximateSeedSize: Int = 200
    @State private var isRunning: Bool = false
    
    var body: some View {
        List {
            Section {
                CountOverview()
            } header: {
                Text("Total Count")
            } footer: {
                Text("Displaying only the entities meant to test relationships.")
            }
            Section("Bulk Insert") {
                Stepper(
                    "Target Objects ~\(approximateSeedSize)",
                    value: $approximateSeedSize,
                    in: 50...2000,
                    step: 50
                )
                Button("Seed Related Models") {
                    seedData(targetApproximateCount: approximateSeedSize)
                }
                Button("Clear All Data", role: .destructive, action: clearAll)
                    .tint(.red)
            }
            Section("Random Inserts") {
                Button("Insert `User` with `Profile`") {
                    insertUserWithProfile()
                }
                Button("Insert Post for Random `User`") {
                    insertPostForRandomUser()
                }
                Button("Insert Comment for Random `User` and `Post`") {
                    insertCommentOnRandomUserPost()
                }
                Button("Insert Random `ActivityLog` (Maybe Unowned)") {
                    insertRandomActivityLog()
                }
            }
            Section("Random Updates") {
                Button("Rename Random User") {
                    renameRandomUser()
                }
                Button("Retitle Random Post") {
                    retitleRandomPost()
                }
                Button("Change Random GroupMembership Role") {
                    updateRandomMembershipRole()
                }
            }
            Section("Random Deletes (Exercise Delete Rule)") {
                Button(role: .destructive, action: deleteRandomUser) {
                    LabeledContent {
                        Text("Test Cascades.")
                    } label: {
                        Text("Delete Random User")
                    }
                }
                Button(role: .destructive, action: deleteRandomPost) {
                    LabeledContent {
                        Text("Test Post.comments Cascade.")
                    } label: {
                        Text("Delete Random Post")
                    }
                }
                Button(role: .destructive, action: deleteRandomGroup) {
                    LabeledContent {
                        Text("Test memberships cascade.")
                    } label: {
                        Text("Delete Random Group")
                    }
                }
                Button(role: .destructive, action: deleteRandomTag) {
                    LabeledContent {
                        Text("Test many-to-many join.")
                    } label: {
                        Text("Delete Random Tag")
                    }
                }
            }
            .labeledContentStyle(BasicListLabeledContentStyle())
        }
        .modifier(RunningOperationModifier(isRunning: $isRunning))
    }
    
    struct CountOverview: View {
        var body: some View {
            ModelCount<User>()
            ModelCount<Profile>()
            ModelCount<Post>()
            ModelCount<Tag>()
            ModelCount<Cluster>()
            ModelCount<Membership>()
            ModelCount<Activity>()
        }
    }
    
    struct RunningOperationModifier: ViewModifier {
        @Binding var isRunning: Bool
        
        func body(content: Content) -> some View {
            ZStack {
                content
                if isRunning {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 200)
                        .clipShape(.rect(cornerRadius: 15))
                        .overlay(ProgressView().controlSize(.large))
                        .transition(.scale)
                }
            }
            .animation(.bouncy.speed(1.5), value: isRunning)
        }
    }
}

private extension StoreOperationsView {
    func save(_ modelContext: ModelContext) {
        do {
            try modelContext.save()
            logger.info("Save successful.")
        } catch {
            logger.error("Save error: \(error)")
        }
    }
    
    func seedData(targetApproximateCount: Int = 200) {
        let baseTotal: Double = 200
        let scale = max(0.25, Double(targetApproximateCount) / baseTotal)
        let userCount = Int((20.0 * scale).rounded(.awayFromZero))
        let groupCount = Int((4.0  * scale).rounded(.awayFromZero))
        let logsCount = Int((40.0 * scale).rounded(.awayFromZero))
        let tagNames = ["swift", "ios", "db", "orm", "schema", "test", "random"]
        var createdTags = [Tag]()
        for name in tagNames {
            let tag = Tag(value: name)
            createdTags.append(tag)
            modelContext.insert(tag)
        }
        var createdGroups = [Cluster]()
        for _ in 0..<groupCount {
            let group = Cluster()
            createdGroups.append(group)
            modelContext.insert(group)
        }
        var createdUsers = [User]()
        var createdPosts = [Post]()
        for _ in 0..<userCount {
            let user = User()
            let profile = Profile(user: user)
            user.profile = profile
            modelContext.insert(user)
            modelContext.insert(profile)
            createdUsers.append(user)
            if Bool.random(), let randomManager = createdUsers.randomElement(),
               randomManager !== user {
//                user.manager = randomManager
            }
            let postCount = Int.random(in: 3...5)
            for _ in 0..<postCount {
                let post = Post(author: user)
                let sampleTags = createdTags.shuffled().prefix(Int.random(in: 1...3))
                post.tags.append(contentsOf: sampleTags)
                modelContext.insert(post)
                createdPosts.append(post)
            }
        }
        for post in createdPosts {
            let commentCount = Int.random(in: 2...6)
            for _ in 0..<commentCount {
                if let randomAuthor = createdUsers.randomElement() {
                    let comment = Post(author: randomAuthor, original: post)
                    modelContext.insert(comment)
                }
            }
        }
        for group in createdGroups {
            let baseRange = 5...10
            let rawMin = Int(Double(baseRange.lowerBound) * scale)
            let rawMax = Int(Double(baseRange.upperBound) * scale)
            let minMembers = clamp(rawMin, to: 1...1000)
            let maxMembers = clamp(max(rawMax, minMembers), to: minMembers...2000)
            let memberCount = Int.random(in: minMembers...maxMembers)
            let shuffledUsers = createdUsers.shuffled().prefix(memberCount)
            for user in shuffledUsers {
                let membership = Membership(
                    role: Bool.random() ? "admin" : "member",
                    user: user,
                    group: group
                )
                modelContext.insert(membership)
            }
        }
        func clamp<T: Comparable>(_ value: T, to range: ClosedRange<T>) -> T {
            min(max(value, range.lowerBound), range.upperBound)
        }
        for _ in 0..<logsCount {
            let maybeUser = Bool.random() ? createdUsers.randomElement() : nil
            let log = Activity(
                message: "Log \(randomName(length: 5))",
                user: maybeUser
            )
            modelContext.insert(log)
        }
        save(modelContext)
    }
    
    func fetch<T>(_ type: T.Type) -> [T] where T: PersistentModel {
        do {
            let models = try modelContext.fetch(FetchDescriptor<T>())
            logger.debug("Fetched \(models.count) \(T.self) models to run preset.")
            return models
        } catch {
            logger.error("Unable to fetch \(T.self) models to run preset: \(error)")
            return []
        }
    }
    
    func clearAll() {
        for type in SampleSchema.models {
            for model in fetch(type) { modelContext.delete(model) }
        }
    }
    
    func run(operation: @MainActor @escaping () -> Void) {
        isRunning = true
        Task {
            try await Task.sleep(for: .seconds(3))
            operation()
            save(modelContext)
            isRunning = false
        }
    }
    
    func insertUserWithProfile() {
        run {
            let user = User()
            let profile = Profile(user: user)
            user.profile = profile
            modelContext.insert(user)
            modelContext.insert(profile)
        }
    }
    
    func insertPostForRandomUser() {
        run {
            guard let user = fetch(User.self).randomElement() else {
                return
            }
            
            let post = Post(author: user)
            modelContext.insert(post)
        }
    }
    
    func insertCommentOnRandomUserPost() {
        run {
            guard let author = fetch(User.self).randomElement(),
                  let post = fetch(Post.self).randomElement() else {
                return
            }
            let comment = Post(author: author, original: post)
            modelContext.insert(comment)
        }
    }
    
    func insertRandomActivityLog() {
        run {
            let maybeUser = Bool.random() ? fetch(User.self).randomElement() : nil
            let log = Activity(
                message: "Random log \(randomName(length: 4))",
                user: maybeUser
            )
            modelContext.insert(log)
        }
    }
    
    func renameRandomUser() {
        run {
            guard let user = fetch(User.self).randomElement() else {
                return
            }
            user.name = "User-\(randomName(length: 4))"
        }
    }
    
    func retitleRandomPost() {
        run {
            guard let post = fetch(Post.self).randomElement() else {
                return
            }
            post.title = "Post-\(randomName(length: 5))"
        }
    }
    
    func updateRandomMembershipRole() {
        run {
            guard let membership = fetch(Membership.self).randomElement() else {
                return
            }
            membership.role = (membership.role == "admin") ? "member" : "admin"
        }
    }
    
    func deleteRandomUser() {
        run {
            guard let user = fetch(User.self).randomElement() else {
                return
            }
            modelContext.delete(user)
        }
    }
    
    func deleteRandomPost() {
        run {
            guard let post = fetch(Post.self).randomElement() else {
                return
            }
            modelContext.delete(post)
        }
    }
    
    func deleteRandomGroup() {
        run {
            guard let group = fetch(Cluster.self).randomElement() else {
                return
            }
            modelContext.delete(group)
        }
    }
    
    func deleteRandomTag() {
        run {
            guard let tag = fetch(Tag.self).randomElement() else {
                return
            }
            modelContext.delete(tag)
        }
    }
}
