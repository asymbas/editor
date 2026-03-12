//
//  Application.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import Logging
import SwiftData
import SwiftUI

#if canImport(Shared)
import Shared
#endif

#Preview {
    Circle()
}

nonisolated let logger: Logger = .init(label: "com.asymbas.datastorekit.application")

nonisolated private let shouldPrint: Bool = {
    #if !SwiftPlaygrounds
    true
    #else
    false
    #endif
}()

@main
struct Application: App {
    @Environment(\.configurator) private var configurator
    
    init() {
        LoggingSystem.bootstrap { label in
            #if DEBUG
            MultiplexLogHandler([
                StreamLogHandler.standardOutput(label: label),
                ProxyLogHandler(
                    label: label,
                    destinations: [
                        ConsoleLogHandler(label: label),
                        PreviewLogHandler(label: label)
                    ]
                ),
                {
                    var handler = DefaultLogHandler(
                        label: label,
                        mode: .compiler,
                        output: nil,
                        isActive: shouldPrint,
                        includeMetadata: true,
                        date: .omitted,
                        time: .standard
                    )
                    switch label.split(separator: ".") {
                    case let components where components.last == "query":
                        handler.logLevel = .trace
                    case let components where components.last == "datastorekit":
                        handler.logLevel = .debug
                    case let components where components.contains("datastorekit"):
                        handler.logLevel = .debug
                    default:
                        handler.logLevel = .info
                    }
                    if !label.split(separator: ".").contains("datastorekit") {
                        handler.logLevel = .critical
                    }
                    return handler
                }()
            ])
            #else
            SwiftLogNoOpLogHandler()
            #endif
        }
    }
    
    var body: some Scene {
        #if true || SwiftPlaygrounds && os(iOS)
        WindowGroup {
            ContentView()
        }
        #else
        DocumentGroup {
            DataStoreKitDocument(template: .empty)
        } editor: {
            DatabaseDocumentView(document: $0.document, packageURL: $0.fileURL)
        }
        .defaultSize(width: 900, height: 600)
        DocumentGroupLaunchScene {
            NewDatabaseLaunchSceneView()
        }
        #endif
    }
}
