//
//  FoodDataClientFactory.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

enum FoodDataClientFactory {
    private static let defaultBaseURL: URL = {
        guard let url = URL(string: "https://api.calry.org") else {
            fatalError("Invalid default base URL")
        }
        return url
    }()

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
        baseURL: URL? = nil,
        authHeader: String? = nil,
        authValue: String? = nil
    ) -> FoodDataClient {
        let proxyClient = ProxyClientImpl(
            baseURL: baseURL ?? defaultBaseURL,
            authHeader: authHeader,
            authValue: authValue
        )

        return FoodDataClientAdapter(
            proxyClient: proxyClient,
            normalizationService: FoodNormalizationServiceImpl()
        )
    }

    static func makeMockClient() -> FoodDataClient {
        FDCMock()
    }
}
