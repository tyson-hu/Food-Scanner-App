//
//  FoodScannerApp.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/17/25.
//

import SwiftData
import SwiftUI

@main
struct FoodScannerApp: App {
    // Compose once at launch
    @State private var appEnv = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(for: [FoodEntry.self])
                .environment(\.appEnv, appEnv)
        }
    }
}
