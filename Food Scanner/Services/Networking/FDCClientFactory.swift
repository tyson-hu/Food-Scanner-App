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
        let wantsRemote = env.runtimeOverrideRemote || env.buildDefaultRemote || env.isRelease
        
        if wantsRemote {
            if let key = env.apiKey, !key.isEmpty {
                #if DEBUG
                debugPrint("FDC DI: Selecting FDCRemoteClient (key present).")
                #endif
                return FDCRemoteClient(apiKey: key)
            } else {
                #if DEBUG
                debugPrint("FDC DI: Remote requested but API key missing - falling back to FDCMock.")
                #endif
            }
        } else {
            #if DEBUG
            debugPrint("FDC DI: Using FDCMock (default).")
            #endif
        }
        
        return FDCMock()
    }
}
