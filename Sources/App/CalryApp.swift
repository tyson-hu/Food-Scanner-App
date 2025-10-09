//
//  CalryApp.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftData
import SwiftUI

@main
struct CalryApp: App {
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
