//
//  AppEnvironment.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftUI

struct AppEnvironment: Sendable {
    // Services
    let fdcClient: FoodDataClient
    let cacheService: FDCCacheService

    // Utilities
    var dateProvider: @Sendable () -> Date = { Date() }

    // Live composition (decides Mock vs Remote via flag/override)
    static func live() -> AppEnvironment {
        let launch = AppLaunchEnvironment.fromProcess()
        let client = FoodDataClientFactory.make(env: launch)

        if let cachedClient = client as? FoodDataCachedClient {
            return AppEnvironment(
                fdcClient: cachedClient,
                cacheService: cachedClient.cacheService,
                dateProvider: { Date() }
            )
        } else {
            let cacheService = FDCCacheService()
            let wrapped = FoodDataCachedClient(underlyingClient: client, cacheService: cacheService)
            return AppEnvironment(
                fdcClient: wrapped,
                cacheService: cacheService,
                dateProvider: { Date() }
            )
        }
    }

    // Used as a safe default for previews / if not injected
    static let preview = AppEnvironment(
        fdcClient: FDCMock(),
        cacheService: FDCCacheService(),
        dateProvider: { Date(timeIntervalSince1970: 0) }
    )
}

private struct AppEnvironmentKey: EnvironmentKey {
    // Keep default harmless (Mock) so previews don't crash
    static let defaultValue = AppEnvironment.preview
}

extension EnvironmentValues {
    var appEnv: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
