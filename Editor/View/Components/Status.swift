//
//  Status.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

enum Status: String, Equatable {
    case idle
    case running
    case success
    case failure
    
    var systemImage: String {
        switch self {
        case .idle: "circle.dotted"
        case .running: "arrow.triangle.2.circlepath.circle.fill"
        case .success: "checkmark.circle.fill"
        case .failure: "xmark.octagon.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .idle: .gray
        case .running: .blue
        case .success: .green
        case .failure: .red
        }
    }
    
    var title: String {
        switch self {
        case .idle: "Idle"
        case .running: "Running"
        case .success: "Passed"
        case .failure: "Failed"
        }
    }
    
    @MainActor @ViewBuilder var icon: some View {
        Image(systemName: systemImage)
            .imageScale(.large)
            .foregroundStyle(color)
    }
    
    @MainActor @ViewBuilder var badge: some View {
        Text(title)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
