//
//  MealSectionView.swift
//  Calry
//
//  Created by Tyson Hu on 10/13/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import SwiftUI

struct MealSectionView: View {
    let meal: Meal
    let entries: [FoodEntryDTO]
    let onAddFood: () -> Void
    let onEditEntry: (UUID) -> Void
    let onDeleteEntry: (UUID) -> Void

    private var mealTotalCalories: Double {
        entries.reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(meal.displayName)
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.primary)

                    Text("\(Int(mealTotalCalories)) calories")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondary)
                }

                Spacer()

                Button(
                    action: onAddFood,
                    label: {
                        Image(systemName: "plus.circle.fill")
                            .font(AppTheme.Typography.title2)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                )
                .accessibilityLabel("Add food to \(meal.displayName)")
            }

            if entries.isEmpty {
                emptyStateView
            } else {
                entriesListView
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    @ViewBuilder
    private var emptyStateView: some View {
        Button(action: onAddFood) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.Colors.secondary)

                Text("Add \(meal.displayName)")
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(AppTheme.Colors.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.lg)
            .background(AppTheme.Colors.tertiary)
            .cornerRadius(AppTheme.CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var entriesListView: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(entries, id: \.id) { entry in
                FoodEntryRowView(
                    entry: entry,
                    onEdit: { onEditEntry(entry.id) },
                    onDelete: { onDeleteEntry(entry.id) }
                )
            }
        }
    }
}

extension Meal {
    var displayName: String {
        switch self {
        case .breakfast:
            return "Breakfast"
        case .lunch:
            return "Lunch"
        case .dinner:
            return "Dinner"
        case .snack:
            return "Snacks"
        }
    }
}

#Preview {
    VStack(spacing: AppTheme.Spacing.lg) {
        MealSectionView(
            meal: .breakfast,
            entries: [],
            onAddFood: {},
            onEditEntry: { _ in },
            onDeleteEntry: { _ in }
        )

        MealSectionView(
            meal: .lunch,
            entries: [sampleChickenEntry],
            onAddFood: {},
            onEditEntry: { _ in },
            onDeleteEntry: { _ in }
        )
    }
    .padding()
}

private let sampleChickenEntry = FoodEntryDTO(
    id: UUID(),
    kind: .catalog,
    name: "Grilled Chicken Breast",
    meal: .lunch,
    quantity: 100,
    unit: "grams",
    foodGID: "sample-gid",
    customName: nil,
    gramsResolved: 100,
    note: nil,
    snapEnergyKcal: 165,
    snapProtein: 31,
    snapFat: 3.6,
    snapSaturatedFat: nil,
    snapCarbs: 0,
    snapFiber: nil,
    snapSugars: nil,
    snapAddedSugars: nil,
    snapSodium: nil,
    snapCholesterol: nil,
    brand: nil,
    fdcId: nil,
    servingDescription: "100g",
    resolvedToBase: 100,
    baseUnit: "grams",
    calories: 165,
    protein: 31,
    fat: 3.6,
    carbs: 0,
    nutrientsSnapshot: [:],
    date: Date()
)
