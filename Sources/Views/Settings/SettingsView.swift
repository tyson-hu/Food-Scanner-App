//
//  SettingsView.swift
//  Calry
//
//  Created by Tyson Hu on 9/21/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
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
            developerSection()
            cacheSection()
            versionSection()
        }
        .navigationTitle("Settings")
    }

    @ViewBuilder
    private func developerSection() -> some View {
        #if DEBUG
            Section("Developer") {
                Toggle("Use FDC Proxy", isOn: $useRemote)
                    .onChange(of: useRemote) { _, newValue in
                        updateUseRemoteSetting(newValue)
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
    }

    @ViewBuilder
    private func cacheSection() -> some View {
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
    }

    @ViewBuilder
    private func versionSection() -> some View {
        Section("Version") {
            Text(appVersion)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
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
        if let cachedClient = appEnv.fdcClient as? FoodDataCachedClient {
            // Check the underlying client type
            (cachedClient.underlyingClientType is FoodDataClientAdapter) ? "Proxy" : "Mock"
        } else {
            // Direct client (shouldn't happen in normal app flow)
            (appEnv.fdcClient is FoodDataClientAdapter) ? "Proxy" : "Mock"
        }
    }

    private func updateUseRemoteSetting(_ newValue: Bool) {
        UserDefaults.standard.set(
            newValue,
            forKey: AppLaunchEnvironment.runtimeKey
        )
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environment(\.appEnv, .preview)
}
