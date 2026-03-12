//
//  TestButton.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreSupport
import SwiftData
import SwiftUI

#if canImport(Shared)
import Shared
#endif

struct TestButton<T, Label>: View where Label: View {
    @Environment(\.autoRunOnAppear) private var autoRunOnAppear
    @State private var status: Status = .idle
    private var label: Label
    private let action: @DatabaseActor () async throws -> T
    private let onEvaluation: @DatabaseActor (T) async throws -> Bool
    
    init(
        _ titleKey: LocalizedStringKey,
        systemImage: String,
        action: @escaping @DatabaseActor () async throws -> T,
        onEvaluation: @escaping @DatabaseActor (T) async throws -> Bool
    ) where Label == SwiftUI.Label<Text, Image> {
        self.label = { SwiftUI.Label(titleKey, systemImage: systemImage) }()
        self.action = action
        self.onEvaluation = onEvaluation
    }
    
    var body: some View {
        Button {
            run()
        } label: {
            SwiftUI.Label {
                HStack {
                    label.labelStyle(.titleOnly)
                    if status != .idle {
                        Spacer()
                        HStack {
                            Image(systemName: status.systemImage)
                            Text(status.rawValue)
                                .textCase(.uppercase)
                        }
                        .badgeContainer()
                    }
                }
            } icon: {
                if case .running = self.status {
                    ProgressView()
                        .transition(.scale)
                } else {
                    label.labelStyle(.iconOnly)
                        .symbolRenderingMode(.monochrome)
                        .transition(.scale)
                }
            }
        }
        .opacity(status == .running ? 0.5 : 1.0)
        .disabled(status == .running)
        .foregroundStyle(status.color, status.color)
        .animation(.spring, value: status)
        .onAppear {
            if autoRunOnAppear {
                Task { run() }
            }
        }
    }
    
    private func run() {
        self.status = .running
        Task { @DatabaseActor in
            do {
                let value = try await action()
                if try await onEvaluation(value) {
                    await MainActor.run { self.status = .success }
                } else {
                    await MainActor.run { self.status = .failure }
                }
            } catch {
                Banner(.error, "Test Error") {
                    "\(error)"
                }
                await MainActor.run { self.status = .failure }
            }
        }
    }
    
//    enum Status: String, Hashable {
//        case idle
//        case running
//        case success
//        case failure
//        
//        var systemImage: String {
//            switch self {
//            case .idle: "pause.circle"
//            case .running: "arrow.triangle.2.circlepath"
//            case .success: "checkmark.circle.fill"
//            case .failure: "xmark.octagon.fill"
//            }
//        }
//        
//        var color: Color {
//            switch self {
//            case .idle: .accentColor
//            case .running: .gray
//            case .success: .green
//            case .failure: .red
//            }
//        }
}
