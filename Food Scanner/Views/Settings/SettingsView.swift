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

            Section("Version") {
                Text(appVersion)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }

    private var appVersion: String {
        // Release or Debug
        #if DEBUG
            return (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown") + " (Debug Build)"
        #else
            return (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown") + " (Release Build)"
        #endif
    }

    private var activeClientName: String {
        (appEnv.fdcClient is FDCProxyClient) ? "Proxy" : "Mock"
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environment(\.appEnv, .preview)
}
