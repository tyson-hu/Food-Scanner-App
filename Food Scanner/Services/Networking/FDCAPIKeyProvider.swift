//
//  FDCAPIKeyProvider.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/21/25.
//

import Foundation

protocol FDCAPIKeyProviding {
    func loadAPIKey() -> String?
}

struct DebugPlistKeyProvider: FDCAPIKeyProviding {
    func loadAPIKey() -> String? {
        #if DEBUG
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let dict = NSDictionary(contentsOf: url) as? [String: Any] {
            return dict["FDC_API_KEY"] as? String
        }
        #endif
        return nil
    }
}

/// For Release, prefer NO key in app. Later, swap to a remote token fetcher that talks to your backend.
/// Placeholder returns nil → triggers fallback to mock unless you stand up the proxy.
struct ReleaseNoKeyProvider: FDCAPIKeyProviding {
    func loadAPIKey() -> String? { nil }
}

/// Chooses the right provider per configuration.
enum FDCAPIKeyProvider {
    static func make() -> FDCAPIKeyProviding {
        #if DEBUG
            return DebugPlistKeyProvider()
        #else
            return ReleaseNoKeyProvider()
        #endif
    }
}
