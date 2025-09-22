//
//  AppLaunchEnvironment.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/21/25.
//

import Foundation

struct AppLaunchEnvironment {
    let isRelease: Bool
    let buildDefaultRemote: Bool
    let runtimeOverrideRemote: Bool
    let apiKey: String?
    
    static let runtimeKey = "feature.fdcRemote" // Debug-only toggle
    
    static func fromProcess(userDefaults: UserDefaults = .standard, bundle: Bundle = .main) -> Self {
        #if DEBUG
        let isRelease = false
        #else
        let isRelease = true
        #endif
        
        // "0" / "1" string emitted by Info.plist from xcconfig
        let builtIn = (bundle.object(forInfoDictionaryKey: "FeatureFDCRemoteDefault") as? String) == "1"
        
        #if DEBUG
        let override = userDefaults.bool(forKey: Self.runtimeKey)
        #else
        let override: Bool = false
        #endif
        
        let apiKey = FDCAPIKeyProvider.make().loadAPIKey()
        
        return .init(
            isRelease: isRelease,
            buildDefaultRemote: builtIn,
            runtimeOverrideRemote: override,
            apiKey: apiKey
        )
    }
}
