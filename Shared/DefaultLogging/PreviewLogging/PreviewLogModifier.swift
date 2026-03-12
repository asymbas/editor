//
//  PreviewLogModifier.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct PreviewLogModifier: ViewModifier {
    @AppStorage(.isEnabled, store: .preview) var isEnabled: Bool = true
    
    func body(content: Self.Content) -> some View {
        content.overlay {
            if isEnabled {
                PreviewLogView()
            }
        }
    }
}

extension View {
    public func loggerPreviewAttachment(isEnabled: Bool = true) -> some View {
        modifier(PreviewLogModifier(isEnabled: isEnabled))
    }
}
