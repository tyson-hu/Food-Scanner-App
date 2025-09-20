//
//  RootView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/17/25.
//

import SwiftUI
import SwiftData

// MARK: - App Root
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var tab: AppTab = .today
    @State private var addActivation: AddActivation? // deep-link placeholder
    
    var body: some View {
        TabView(selection: $tab) {
            Tab("Today", systemImage: "text.rectangle.page", value: .today) {
                // MARK: Temp add NavigationStack here, will move after adding sub page for TodayView -> TodayRoot
                NavigationStack { TodayView() }
            }
            
            Tab("Profile", systemImage: "person.crop.circle", value: .profile) {
                Text("Profile page")
            }
            
            Tab("Add", systemImage: "plus", value: .add, role: .search) {
                AddFoodHomeView(activation: $addActivation, onLogged: { entry in
                    modelContext.insert(entry)
                    do {
                        try modelContext.save()
                    } catch {
                        assertionFailure("Failed to save FoodEntry: \(error)")
                    }
                    tab = .today
                })
            }
        }
        .environment(\.appEnv, AppEnvironment())
    }
}

#Preview {
    RootView()
}
