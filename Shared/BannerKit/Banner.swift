//
//  Banner.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Logging
import SwiftUI

public struct Banner {
    internal struct Model: Identifiable {
        internal var id: UUID = .init()
        internal var title: String
        internal var description: String?
        internal var systemImage: String?
        internal var edge: VerticalEdge
        internal var timeout: Duration
        internal var foreground: Color?
        internal var background: Color?
        internal var customView: (@MainActor () -> AnyView)?
        internal var level: Logger.Level
    }
    
    public struct Payload: Equatable, Sendable {
        internal var title: String?
        internal var description: String?
        internal var systemImage: String?
        internal var foreground: Color?
        internal var background: Color?
    }
    
    public struct Preset: Equatable, Sendable {
        public let systemImage: String?
        public let foreground: Color?
        public let background: Color?
        public let level: Logger.Level
        
        public init(
            systemImage: String? = nil,
            foreground: Color? = nil,
            background: Color? = nil,
            level: Logger.Level = .info
        ) {
            self.systemImage = systemImage
            self.foreground = foreground
            self.background = background
            self.level = level
        }
    }
}

extension Banner.Preset {
    public static let `default`: Self = .init()
    
    public static var error: Self {
        .init(
            systemImage: "exclamationmark.circle.fill",
            foreground: .white,
            background: .red.opacity(0.5),
            level: .error
        )
    }
    
    public static var warning: Self {
        .init(
            systemImage: "exclamationmark.triangle.fill",
            foreground: .black,
            background: .yellow,
            level: .warning
        )
    }
    
    public static var info: Self {
        .init(
            systemImage: "info.circle.fill",
            foreground: .white,
            background: .blue,
            level: .info
        )
    }
    
    public static var ok: Self {
        .init(
            systemImage: "checkmark.circle.fill",
            foreground: .white,
            background: .green,
            level: .info
        )
    }
}
