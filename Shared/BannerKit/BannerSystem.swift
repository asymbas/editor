//
//  BannerSystem.swift
//  Core
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Logging
import Observation
import SwiftUI

@globalActor internal actor BannerActor {
    nonisolated internal static let shared: BannerActor = .init()
}

@Observable final class BannerSystem: Sendable {
    nonisolated internal static let shared: BannerSystem = .init()
    nonisolated internal static let logger: Logger = .init(label: "com.asymbas.bannerkit")
    @MainActor internal var banners: [Banner.Model] = []
    @MainActor private var dismissalTasks: [UUID: Task<Void, any Swift.Error>] = [:]
    @MainActor private let maxVisibleBanners: Int = 3
    
    nonisolated private init() {}
    
    @MainActor internal func banners(for edge: VerticalEdge) -> [Banner.Model] {
        banners.filter { $0.edge == edge }
    }
    
    @BannerActor internal func enqueue(_ banner: Banner.Model) async {
        BannerSystem.logger.log(
            level: banner.level,
            Logger.Message(stringLiteral: {
                guard let description = banner.description else {
                    return banner.title
                }
                return "\(banner.title): \(description)"
            }()),
            metadata: nil,
            source: nil
        )
        await MainActor.run {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                banners.append(banner)
                while banners.count > maxVisibleBanners {
                    if let oldest = self.banners.first {
                        dismiss(oldest.id, animated: false)
                    } else {
                        break
                    }
                }
            }
            scheduleDismissal(for: banner)
        }
    }
    
    @MainActor internal func dismiss(_ id: UUID, animated: Bool = true) {
        dismissalTasks.removeValue(forKey: id)?.cancel()
        guard let index = self.banners.firstIndex(where: { $0.id == id }) else {
            return
        }
        if animated {
            _ = withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                banners.remove(at: index)
            }
        } else {
            banners.remove(at: index)
        }
    }
    
    @MainActor private func scheduleDismissal(for banner: Banner.Model) {
        let banner = banner
        dismissalTasks[banner.id]?.cancel()
        dismissalTasks[banner.id] = Task {
            try await Task.sleep(for: banner.timeout)
            await MainActor.run { BannerSystem.shared.dismiss(banner.id) }
        }
    }
}
