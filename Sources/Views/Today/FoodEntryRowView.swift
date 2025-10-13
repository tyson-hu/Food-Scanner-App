//
//  FoodEntryRowView.swift
//  Calry
//
//  Created by Tyson Hu on 10/13/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import SwiftUI

struct FoodEntryRowView: View {
    let entry: FoodEntryDTO
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(entry.name)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primary)
                    .lineLimit(2)

                Text(entry.servingDescription)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                Text("\(Int(entry.calories))")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.calories)

                Text("kcal")
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.Colors.secondary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .padding(.horizontal, AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.md)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Edit", systemImage: "pencil") {
                onEdit()
            }
            .tint(AppTheme.Colors.primary)

            Button("Delete", systemImage: "trash") {
                onDelete()
            }
            .tint(AppTheme.Colors.error)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.name), \(entry.servingDescription)")
        .accessibilityValue("\(Int(entry.calories)) calories")
        .accessibilityHint("Swipe right to edit or delete")
    }
}

#Preview {
    VStack(spacing: AppTheme.Spacing.md) {
        FoodEntryRowView(
            entry: sampleChickenEntry,
            onEdit: {},
            onDelete: {}
        )

        FoodEntryRowView(
            entry: sampleRiceEntry,
            onEdit: {},
            onDelete: {}
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

private let sampleRiceEntry = FoodEntryDTO(
    id: UUID(),
    kind: .catalog,
    name: "Brown Rice",
    meal: .dinner,
    quantity: 1,
    unit: "serving",
    foodGID: "sample-gid-2",
    customName: nil,
    gramsResolved: 195,
    note: nil,
    snapEnergyKcal: 220,
    snapProtein: 5,
    snapFat: 1.8,
    snapSaturatedFat: nil,
    snapCarbs: 45,
    snapFiber: nil,
    snapSugars: nil,
    snapAddedSugars: nil,
    snapSodium: nil,
    snapCholesterol: nil,
    brand: nil,
    fdcId: nil,
    servingDescription: "1 cup cooked",
    resolvedToBase: 1,
    baseUnit: "serving",
    calories: 220,
    protein: 5,
    fat: 1.8,
    carbs: 45,
    nutrientsSnapshot: [:],
    date: Date()
)
