//
//  BannerOutput.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Logging
import SwiftUI

public extension Banner {
    @discardableResult nonisolated init(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        foreground: Color? = nil,
        background: Color? = nil,
        systemImage: String? = nil,
        level: Logger.Level = .info,
        _ operation: () -> Payload
    ) {
        let payload = operation()
        Task { @concurrent in
            await BannerSystem.shared.enqueue(
                Model(
                    title: payload.title ?? "",
                    description: nil,
                    systemImage: payload.systemImage ?? systemImage,
                    edge: edge,
                    timeout: timeout,
                    foreground: payload.foreground ?? foreground,
                    background: payload.background ?? background,
                    level: level
                )
            )
        }
    }
    
    @discardableResult nonisolated init(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        foreground: Color? = nil,
        background: Color? = nil,
        systemImage: String? = nil,
        level: Logger.Level = .info,
        _ operation: () -> String
    ) {
        self.init(
            edge: edge,
            timeout: timeout,
            foreground: foreground,
            background: background,
            systemImage: systemImage,
            level: level
        ) {
            Payload(title: operation())
        }
    }
}

extension Banner {
    @discardableResult nonisolated init(
        _ preset: Preset,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> Payload
    ) {
        let payload = operation()
        Task { @MainActor in
            await BannerSystem.shared.enqueue(
                Model(
                    title: payload.title ?? "",
                    description: nil,
                    systemImage: payload.systemImage ?? preset.systemImage,
                    edge: edge,
                    timeout: timeout,
                    foreground: payload.foreground ?? preset.foreground,
                    background: payload.background ?? preset.background,
                    level: preset.level
                )
            )
        }
    }
    
    @discardableResult nonisolated init(
        _ preset: Preset,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> String
    ) {
        self.init(
            preset,
            edge: edge,
            timeout: timeout
        ) {
            Payload(title: operation())
        }
    }
    
    @discardableResult nonisolated public init(
        _ preset: Preset,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @autoclosure () -> String
    ) {
        self.init(
            preset,
            edge: edge,
            timeout: timeout
        ) {
            Payload(title: operation())
        }
    }
}

public extension Banner {
    @discardableResult nonisolated init(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        foreground: Color? = nil,
        background: Color? = nil,
        _ titleKey: String,
        systemImage: String? = nil,
        level: Logger.Level = .info,
        _ operation: () -> Payload
    ) {
        let payload = operation()
        Task { @concurrent in
            await BannerSystem.shared.enqueue(
                Model(
                    title: titleKey,
                    description: payload.description,
                    systemImage: payload.systemImage ?? systemImage,
                    edge: edge,
                    timeout: timeout,
                    foreground: payload.foreground ?? foreground,
                    background: payload.background ?? background,
                    customView: nil,
                    level: level
                )
            )
        }
    }
    
    @discardableResult nonisolated init(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        foreground: Color? = nil,
        background: Color? = nil,
        _ titleKey: String,
        systemImage: String? = nil,
        level: Logger.Level = .info,
        _ operation: () -> String
    ) {
        self.init(
            edge: edge,
            timeout: timeout,
            foreground: foreground,
            background: background,
            titleKey,
            systemImage: systemImage,
            level: level
        ) {
            Payload(description: operation())
        }
    }
}

public extension Banner {
    @discardableResult nonisolated init(
        _ preset: Preset,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ titleKey: String,
        _ operation: () -> Payload
    ) {
        let payload = operation()
        Task { @MainActor in
            await BannerSystem.shared.enqueue(
                Model(
                    title: titleKey,
                    description: payload.description,
                    systemImage: payload.systemImage ?? preset.systemImage,
                    edge: edge,
                    timeout: timeout,
                    foreground: payload.foreground ?? preset.foreground,
                    background: payload.background ?? preset.background,
                    customView: nil,
                    level: preset.level
                )
            )
        }
    }
    
    @discardableResult nonisolated init(
        _ preset: Preset,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ titleKey: String,
        _ operation: () -> String
    ) {
        self.init(
            preset,
            edge: edge,
            timeout: timeout,
            titleKey
        ) {
            Payload(description: operation())
        }
    }
}

public extension Banner {
    @discardableResult nonisolated init<Content: View>(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        foreground: Color? = nil,
        background: Color? = nil,
        systemImage: String? = nil,
        level: Logger.Level = .info,
        _ operation: @escaping @Sendable () -> Payload,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) {
        Task { @MainActor in
            let payload = operation()
            await BannerSystem.shared.enqueue(
                Model(
                    title: payload.title ?? "",
                    description: payload.description,
                    systemImage: payload.systemImage ?? systemImage,
                    edge: edge,
                    timeout: timeout,
                    foreground: payload.foreground ?? foreground,
                    background: payload.background ?? background,
                    customView: { AnyView(content()) },
                    level: level
                )
            )
        }
    }
    
    @discardableResult nonisolated init<Content: View>(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        foreground: Color? = nil,
        background: Color? = nil,
        systemImage: String? = nil,
        level: Logger.Level = .info,
        _ operation: @escaping @Sendable () -> String,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) {
        self.init(
            edge: edge,
            timeout: timeout,
            foreground: foreground,
            background: background,
            systemImage: systemImage,
            level: level,
            { Payload(title: operation()) },
            content: content
        )
    }
}

public extension Banner {
    @discardableResult nonisolated init<Content: View>(
        _ preset: Preset,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> Payload,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) {
        Task { @MainActor in
            let payload = operation()
            await BannerSystem.shared.enqueue(
                Model(
                    title: payload.title ?? "",
                    description: payload.description,
                    systemImage: payload.systemImage ?? preset.systemImage,
                    edge: edge,
                    timeout: timeout,
                    foreground: payload.foreground ?? preset.foreground,
                    background: payload.background ?? preset.background,
                    customView: { AnyView(content()) },
                    level: preset.level
                )
            )
        }
    }
    
    @discardableResult nonisolated init<Content: View>(
        _ preset: Preset,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> String,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) {
        self.init(
            preset,
            edge: edge,
            timeout: timeout,
            { Payload(title: operation()) },
            content: content
        )
    }
}

public extension Banner {
    @discardableResult static func `default`(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> Payload
    ) -> Banner {
        Banner(.default, edge: edge, timeout: timeout, operation)
    }
    
    @discardableResult static func `default`(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> String
    ) -> Banner {
        Banner(.default, edge: edge, timeout: timeout, operation)
    }
    
    @discardableResult static func `default`(
        _ title: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3)
    ) -> Banner {
        Banner(.default, edge: edge, timeout: timeout) { title }
    }
    
    @discardableResult static func `default`(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> Payload
    ) -> Banner {
        Banner(.default, edge: edge, timeout: timeout, titleKey, operation)
    }
    
    @discardableResult static func `default`(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> String
    ) -> Banner {
        Banner(.default, edge: edge, timeout: timeout, titleKey, operation)
    }
    
    @discardableResult static func `default`<Content: View>(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> Payload,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(.default, edge: edge, timeout: timeout, operation, content: content)
    }
    
    @discardableResult static func `default`<Content: View>(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> String,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(.default, edge: edge, timeout: timeout, operation, content: content)
    }
    
    @discardableResult static func `default`<Content: View>(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> Payload,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(
            .default,
            edge: edge,
            timeout: timeout,
            {
                var payload = operation()
                if payload.title == nil { payload.title = titleKey }
                return payload
            },
            content: content
        )
    }
    
    @discardableResult static func `default`<Content: View>(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> String,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(
            .default,
            edge: edge,
            timeout: timeout,
            { Payload(title: titleKey, description: operation()) },
            content: content
        )
    }
}

public extension Banner {
    @discardableResult static func error(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> Payload
    ) -> Banner {
        Banner(.error, edge: edge, timeout: timeout, operation)
    }
    
    @discardableResult static func error(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> String
    ) -> Banner {
        Banner(.error, edge: edge, timeout: timeout, operation)
    }
    
    @discardableResult static func error(
        _ title: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3)
    ) -> Banner {
        Banner(.error, edge: edge, timeout: timeout) { title }
    }
    
    @discardableResult static func error(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> Payload
    ) -> Banner {
        Banner(.error, edge: edge, timeout: timeout, titleKey, operation)
    }
    
    @discardableResult static func error(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> String
    ) -> Banner {
        Banner(.error, edge: edge, timeout: timeout, titleKey, operation)
    }
    
    @discardableResult static func error<Content: View>(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> Payload,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(.error, edge: edge, timeout: timeout, operation, content: content)
    }
    
    @discardableResult static func error<Content: View>(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> String,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(.error, edge: edge, timeout: timeout, operation, content: content)
    }
    
    @discardableResult static func error<Content: View>(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> Payload,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(
            .error,
            edge: edge,
            timeout: timeout,
            {
                var payload = operation()
                if payload.title == nil { payload.title = titleKey }
                return payload
            },
            content: content
        )
    }
    
    @discardableResult static func error<Content: View>(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> String,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(
            .error,
            edge: edge,
            timeout: timeout,
            { Payload(title: titleKey, description: operation()) },
            content: content
        )
    }
}

public extension Banner {
    @discardableResult static func warning(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> Payload
    ) -> Banner {
        Banner(.warning, edge: edge, timeout: timeout, operation)
    }
    
    @discardableResult static func warning(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> String
    ) -> Banner {
        Banner(.warning, edge: edge, timeout: timeout, operation)
    }
    
    @discardableResult static func warning(
        _ title: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3)
    ) -> Banner {
        Banner(.warning, edge: edge, timeout: timeout) { title }
    }
    
    @discardableResult static func warning(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> Payload
    ) -> Banner {
        Banner(.warning, edge: edge, timeout: timeout, titleKey, operation)
    }
    
    @discardableResult static func warning(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> String
    ) -> Banner {
        Banner(.warning, edge: edge, timeout: timeout, titleKey, operation)
    }
    
    @discardableResult static func warning<Content: View>(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> Payload,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(.warning, edge: edge, timeout: timeout, operation, content: content)
    }
    
    @discardableResult static func warning<Content: View>(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> String,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(.warning, edge: edge, timeout: timeout, operation, content: content)
    }
    
    @discardableResult static func warning<Content: View>(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> Payload,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(
            .warning,
            edge: edge,
            timeout: timeout,
            {
                var payload = operation()
                if payload.title == nil { payload.title = titleKey }
                return payload
            },
            content: content
        )
    }
    
    @discardableResult static func warning<Content: View>(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> String,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(
            .warning,
            edge: edge,
            timeout: timeout,
            { Payload(title: titleKey, description: operation()) },
            content: content
        )
    }
}

public extension Banner {
    @discardableResult static func info(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> Payload
    ) -> Banner {
        Banner(.info, edge: edge, timeout: timeout, operation)
    }
    
    @discardableResult static func info(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> String
    ) -> Banner {
        Banner(.info, edge: edge, timeout: timeout, operation)
    }
    
    @discardableResult static func info(
        _ title: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3)
    ) -> Banner {
        Banner(.info, edge: edge, timeout: timeout) { title }
    }
    
    @discardableResult static func info(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> Payload
    ) -> Banner {
        Banner(.info, edge: edge, timeout: timeout, titleKey, operation)
    }
    
    @discardableResult static func info(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> String
    ) -> Banner {
        Banner(.info, edge: edge, timeout: timeout, titleKey, operation)
    }
    
    @discardableResult static func info<Content: View>(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> Payload,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(.info, edge: edge, timeout: timeout, operation, content: content)
    }
    
    @discardableResult static func info<Content: View>(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> String,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(.info, edge: edge, timeout: timeout, operation, content: content)
    }
    
    @discardableResult static func info<Content: View>(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> Payload,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(
            .info,
            edge: edge,
            timeout: timeout,
            {
                var payload = operation()
                if payload.title == nil { payload.title = titleKey }
                return payload
            },
            content: content
        )
    }
    
    @discardableResult static func info<Content: View>(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> String,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(
            .info,
            edge: edge,
            timeout: timeout,
            { Payload(title: titleKey, description: operation()) },
            content: content
        )
    }
}

public extension Banner {
    @discardableResult static func ok(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> Payload
    ) -> Banner {
        Banner(.ok, edge: edge, timeout: timeout, operation)
    }
    
    @discardableResult static func ok(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> String
    ) -> Banner {
        Banner(.ok, edge: edge, timeout: timeout, operation)
    }
    
    @discardableResult static func ok(
        _ title: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3)
    ) -> Banner {
        Banner(.ok, edge: edge, timeout: timeout) { title }
    }
    
    @discardableResult static func ok(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> Payload
    ) -> Banner {
        Banner(.ok, edge: edge, timeout: timeout, titleKey, operation)
    }
    
    @discardableResult static func ok(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: () -> String
    ) -> Banner {
        Banner(.ok, edge: edge, timeout: timeout, titleKey, operation)
    }
    
    @discardableResult static func ok<Content: View>(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> Payload,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(.ok, edge: edge, timeout: timeout, operation, content: content)
    }
    
    @discardableResult static func ok<Content: View>(
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> String,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(.ok, edge: edge, timeout: timeout, operation, content: content)
    }
    
    @discardableResult static func ok<Content: View>(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> Payload,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(
            .ok,
            edge: edge,
            timeout: timeout,
            {
                var payload = operation()
                if payload.title == nil { payload.title = titleKey }
                return payload
            },
            content: content
        )
    }
    
    @discardableResult static func ok<Content: View>(
        _ titleKey: String,
        edge: VerticalEdge = .bottom,
        timeout: Duration = .seconds(3),
        _ operation: @escaping @Sendable () -> String,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Banner {
        Banner(
            .ok,
            edge: edge,
            timeout: timeout,
            { Payload(title: titleKey, description: operation()) },
            content: content
        )
    }
}
