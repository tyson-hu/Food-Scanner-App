//
//  FoodDataClientFactory.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

enum FoodDataClientFactory {
    static func make(env: AppLaunchEnvironment) -> FoodDataClient {
        // Precedence: runtime override -> build flag -> configuration default (Release)
        let wantsProxy = env.runtimeOverrideRemote || env.buildDefaultRemote || env.isRelease

        let underlyingClient: FoodDataClient
        if wantsProxy {
            #if DEBUG
                debugPrint("FDC DI: Selecting Proxy client (edge mode).")
            #endif
            underlyingClient = makeProxyClient()
        } else {
            #if DEBUG
                debugPrint("FDC DI: Using FDCMock (default).")
            #endif
            underlyingClient = FDCMock()
        }

        // Always wrap in FoodDataCachedClient
        return FoodDataCachedClient(
            underlyingClient: underlyingClient,
            cacheService: FDCCacheService()
        )
    }

    // MARK: - Alternative Factory Methods for Testing

    static func makeProxyClient(
        apiConfig: APIConfiguration? = nil,
        authHeader: String? = nil,
        authValue: String? = nil
    ) -> FoodDataClient {
        do {
            let proxyClient = try ProxyClientImpl(
                apiConfig: apiConfig,
                authHeader: authHeader,
                authValue: authValue
            )

            return FoodDataClientAdapter(
                proxyClient: proxyClient,
                normalizationService: FoodNormalizationServiceImpl()
            )
        } catch {
            fatalError("Failed to create ProxyClient: \(error)")
        }
    }

    static func makeMockClient() -> FoodDataClient {
        FDCMock()
    }
}
