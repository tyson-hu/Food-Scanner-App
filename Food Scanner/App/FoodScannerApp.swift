//
//  Food_ScannerApp.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/17/25.
//

import SwiftUI
import SwiftData

@main
struct FoodScannerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(for: [FoodEntry.self])
        }
    }
}
