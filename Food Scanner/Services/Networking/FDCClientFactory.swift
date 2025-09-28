//
//  FDCClientFactory.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/21/25.
//

import Foundation

enum FDCClientFactory {
    static func make(env: AppLaunchEnvironment) -> FDCClient {
        // Precedence: runtime override -> build flag -> configuration default (Release)
        let wantsProxy = env.runtimeOverrideRemote || env.buildDefaultRemote || env.isRelease

        let underlyingClient: FDCClient
        if wantsProxy {
            #if DEBUG
                debugPrint("FDC DI: Selecting FDCProxyClient (proxy mode).")
            #endif
            underlyingClient = FDCProxyClient()
        } else {
            #if DEBUG
                debugPrint("FDC DI: Using FDCMock (default).")
            #endif
            underlyingClient = FDCMock()
        }

        // Always wrap in FDCCachedClient
        return FDCCachedClient(
            underlyingClient: underlyingClient,
            cacheService: FDCCacheService(),
        )
    }

    // MARK: - Alternative Factory Methods for Testing

    static func makeProxyClient(
        baseURL: URL? = nil,
        authHeader: String? = nil,
        authValue: String? = nil
    ) -> FDCClient {
        FDCProxyClient(
            baseURL: baseURL,
            authHeader: authHeader,
            authValue: authValue
        )
    }

    static func makeMockClient() -> FDCClient {
        FDCMock()
    }
}
