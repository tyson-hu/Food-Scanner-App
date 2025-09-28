//
//  SettingsView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/21/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.appEnv) private var appEnv

    #if DEBUG
        @State private var useRemote = UserDefaults.standard.bool(
            forKey: AppLaunchEnvironment.runtimeKey
        )
    #endif

    var body: some View {
        Form {
            #if DEBUG
                Section("Developer") {
                    Toggle("Use FDC Proxy", isOn: $useRemote)
                        .onChange(of: useRemote) { _, newValue in
                            UserDefaults.standard.set(
                                newValue,
                                forKey: AppLaunchEnvironment.runtimeKey
                            )
                        }

                    LabeledContent("Active FDC Client") {
                        Text(activeClientName)
                            .foregroundStyle(.secondary)
                    }

                    Text("Relaunch the app to apply this toggle.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            #else
                Section {
                    Text("No configurable settings in this build.")
                        .foregroundStyle(.secondary)
                }
            #endif

            Section("Cache") {
                LabeledContent("Cached Items") {
                    Text("\(cacheStats.totalSize)")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Search Cache") {
                    Text("\(cacheStats.searchCount)")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Detail Cache") {
                    Text("\(cacheStats.detailCount)")
                        .foregroundStyle(.secondary)
                }

                Button("Clear Cache") {
                    Task { @MainActor in
                        appEnv.cacheService.clearCache()
                    }
                }
                .foregroundStyle(.red)
            }

            Section("Version") {
                Text(appVersion)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }

    private var appVersion: String {
        // Both Debug and Release should show the marketing version (CFBundleShortVersionString)
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

        #if DEBUG
            return "\(version) (\(buildNumber)) - Debug Build"
        #else
            return "\(version) (\(buildNumber)) - Release Build"
        #endif
    }

    private var cacheStats: CacheStats {
        appEnv.cacheService.cacheStats
    }

    private var activeClientName: String {
        if let cachedClient = appEnv.fdcClient as? FDCCachedClient {
            // Check the underlying client type
            (cachedClient.underlyingClientType is FDCProxyClient) ? "Proxy" : "Mock"
        } else {
            // Direct client (shouldn't happen in normal app flow)
            (appEnv.fdcClient is FDCProxyClient) ? "Proxy" : "Mock"
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environment(\.appEnv, .preview)
}
