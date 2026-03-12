//
//  QueryRun.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreRuntime
import SwiftData
import SwiftUI

extension EnvironmentValues {
    @Entry var autoRunOnAppear: Bool = false
    @Entry var resetBeforeRun: Bool = true
}

struct QueryRun: Equatable, Hashable, Identifiable, Sendable {
    var id: String { date.description }
    var date: Date = .now
    var elapsed: TimeInterval = 0.0
    var status: Status = .idle
    var checks: [Check] = []
    var count: Int = 0
    var error: (any Swift.Error)?
    var sql: String?
    var placeholdersCount: Int?
    var bindingsCount: Int?
    var descriptorDescription: String?
    var predicateDescription: String?
    var tree: PredicateTree?
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.date == rhs.date
        && lhs.elapsed == rhs.elapsed
        && lhs.status == rhs.status
        && lhs.checks == rhs.checks
        && lhs.count == rhs.count
        && lhs.sql == rhs.sql
        && lhs.placeholdersCount == rhs.placeholdersCount
        && lhs.bindingsCount == rhs.bindingsCount
        && lhs.descriptorDescription == rhs.descriptorDescription
        && lhs.predicateDescription == rhs.predicateDescription
        && lhs.tree == rhs.tree
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(elapsed)
        hasher.combine(status)
        hasher.combine(checks)
        hasher.combine(count)
        hasher.combine(sql)
        hasher.combine(placeholdersCount)
        hasher.combine(bindingsCount)
        hasher.combine(descriptorDescription)
        hasher.combine(predicateDescription)
        hasher.combine(tree)
    }
    
    struct Check: Equatable, Hashable, Identifiable, Sendable {
        let title: String
        let description: String?
        let passed: Bool
        
        var id: String { title + (description ?? "") }
    }
    
    enum Status {
        case idle
        case running
        case success
        case warning
        case failure
        
        var color: Color {
            switch self {
            case .idle: .secondary.opacity(0.5)
            case .running: .blue
            case .success: .green
            case .warning: .orange
            case .failure: .red
            }
        }
        
        var backgroundColors: [Color] {
            switch self {
            case .idle: [.baseSecondary, .base]
            case .running: [.blue.opacity(0.35), .base]
            case .success: [.green.opacity(0.4), .base]
            case .warning: [.orange.opacity(0.35), .base]
            case .failure: [.red.opacity(0.35), .base]
            }
        }
        
        var label: String {
            switch self {
            case .idle: "Idle"
            case .running: "Running"
            case .success: "Passed"
            case .warning: "Mismatch"
            case .failure: "Failed"
            }
        }
    }
    
    struct Expectations: Equatable {
        var expectedCount: Int? = nil
        var expectedError: Bool = false
        var expectedBindingsCount: Int? = nil
        var expectedPlaceholdersCount: Int? = nil
        var sqlMustContain: [String] = []
        var sqlMustNotContain: [String] = []
        
        enum Rule {
            case expectedCount(Int)
            case expectedError
            case noError
            case expectedBindingsCount(Int)
            case expectedPlaceholdersCount(Int)
            case sqlMustContain(String)
            case sqlMustNotContain(String)
        }
        
        mutating func apply(_ rule: Rule) {
            switch rule {
            case .expectedCount(let value): expectedCount = value
            case .expectedError: expectedError = true
            case .noError: expectedError = false
            case .expectedBindingsCount(let value): expectedBindingsCount = value
            case .expectedPlaceholdersCount(let value): expectedPlaceholdersCount = value
            case .sqlMustContain(let value): sqlMustContain.append(value)
            case .sqlMustNotContain(let value): sqlMustNotContain.append(value)
            }
        }
        
        static func build(_ rules: [Rule]) -> Expectations {
            var expectations = Expectations()
            for rule in rules { expectations.apply(rule) }
            return expectations
        }
        
        var hasAssertions: Bool {
            expectedCount != nil
            || expectedError
            || expectedBindingsCount != nil
            || expectedPlaceholdersCount != nil
            || !sqlMustContain.isEmpty
            || !sqlMustNotContain.isEmpty
        }
    }
}
