//
//  QuickAddGridView.swift
//  Calry
//
//  Created by Tyson Hu on 10/13/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftUI

struct QuickAddGridView: View {
    let recentFoods: [RecentFoodDTO]
    let favoriteFoods: [RecentFoodDTO]
    let foodNames: [String: String] // foodGID -> name mapping
    let onSelect: (String, Meal) -> Void

    @State private var selectedMeal: Meal = .lunch

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Meal picker
            Picker("Meal", selection: $selectedMeal) {
                ForEach(Meal.allCases, id: \.self) { meal in
                    Text(meal.displayName).tag(meal)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppTheme.Spacing.md)

            // Favorites
            if !favoriteFoods.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    SectionHeaderView(title: "Favorites")
                    foodGrid(favoriteFoods)
                }
            }

            // Recents
            if !recentFoods.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    SectionHeaderView(title: "Recent")
                    foodGrid(recentFoods)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
    }

    private func foodGrid(_ foods: [RecentFoodDTO]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: AppTheme.Spacing.xs) {
            ForEach(foods, id: \.foodGID) { food in
                quickAddCard(food)
            }
        }
    }

    private func quickAddCard(_ food: RecentFoodDTO) -> some View {
        Button {
            onSelect(food.foodGID, selectedMeal)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: food.isFavorite ? "star.fill" : "clock.fill")
                    .font(.title3)
                    .foregroundColor(food.isFavorite ? .yellow : .secondary)

                Text(foodNames[food.foodGID] ?? "Unknown")
                    .font(AppTheme.Typography.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.xs)
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.md)
        }
    }
}

#Preview {
    QuickAddGridView(
        recentFoods: [
            RecentFoodDTO(id: 1, foodGID: "fdc:123", lastUsedAt: Date(), useCount: 5, isFavorite: false),
            RecentFoodDTO(id: 2, foodGID: "fdc:456", lastUsedAt: Date(), useCount: 3, isFavorite: false)
        ],
        favoriteFoods: [
            RecentFoodDTO(id: 3, foodGID: "fdc:789", lastUsedAt: Date(), useCount: 10, isFavorite: true)
        ],
        foodNames: [
            "fdc:123": "Apple",
            "fdc:456": "Banana",
            "fdc:789": "Chicken Breast"
        ],
        onSelect: { _, _ in }
    )
}
