//
//  AppEnvironment.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import SwiftData
import SwiftUI

public struct AppEnvironment: Sendable {
    // Services
    let fdcClient: FoodDataClient
    let cacheService: FDCCacheService
    let foodLogStore: FoodLogStore
    let foodLogRepository: FoodLogRepository

    // Utilities
    var dateProvider: @Sendable () -> Date = { Date() }

    // Live composition (decides Mock vs Remote via flag/override)
    static func live() -> AppEnvironment {
        let launch = AppLaunchEnvironment.fromProcess()
        let client = FoodDataClientFactory.make(env: launch)
        let cacheService = FDCCacheService()
        let cachedClient = FoodDataCachedClient(underlyingClient: client, cacheService: cacheService)

        let schema = Schema([FoodEntry.self, FoodRef.self, UserFoodPrefs.self, RecentFood.self])
        let container: ModelContainer = {
            do { return try ModelContainer(for: schema) } catch {
                preconditionFailure("Failed to create ModelContainer: \(error)")
            }
        }()

        let store = FoodLogStore(container: container)
        let repository = FoodLogRepositorySwiftData(store: store)

        return AppEnvironment(
            fdcClient: cachedClient,
            cacheService: cacheService,
            foodLogStore: store,
            foodLogRepository: repository,
            dateProvider: { Date() }
        )
    }

    // Used as a safe default for previews / if not injected
    static let preview: AppEnvironment = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema = Schema([FoodEntry.self, FoodRef.self, UserFoodPrefs.self, RecentFood.self])
        let container: ModelContainer = {
            do { return try ModelContainer(for: schema, configurations: config) } catch {
                preconditionFailure("Failed to create preview ModelContainer: \(error)")
            }
        }()

        let store = FoodLogStore(container: container)
        let repository = FoodLogRepositorySwiftData(store: store)

        return AppEnvironment(
            fdcClient: FDCMock(),
            cacheService: FDCCacheService(),
            foodLogStore: store,
            foodLogRepository: repository,
            dateProvider: { Date(timeIntervalSince1970: 0) }
        )
    }()
}
