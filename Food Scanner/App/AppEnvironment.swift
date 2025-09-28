//
//  AppEnvironment.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import SwiftUI

struct AppEnvironment: Sendable {
    // Services
    let fdcClient: FDCClient
    let cacheService: FDCCacheService

    // Utilities
    var dateProvider: @Sendable () -> Date = { Date() }

    // Live composition (decides Mock vs Remote via flag/override)
    static func live() -> AppEnvironment {
        let launch = AppLaunchEnvironment.fromProcess()
        let baseClient = FDCClientFactory.make(env: launch)
        let cacheService = FDCCacheService()
        let cachedClient = FDCCachedClient(underlyingClient: baseClient, cacheService: cacheService)
        return AppEnvironment(fdcClient: cachedClient, cacheService: cacheService, dateProvider: { Date() })
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
