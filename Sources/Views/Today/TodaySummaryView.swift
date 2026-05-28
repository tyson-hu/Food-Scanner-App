//
//  TodaySummaryView.swift
//  Calry
//
//  Created by Tyson Hu on 10/13/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftUI

struct TodaySummaryView: View {
    let totals: DayTotals
    let onAddFood: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Calorie ring
            CalorieRingView(
                current: totals.calories,
                target: 2_000, // Default target
                lineWidth: 20
            )
            .frame(width: 200, height: 200)

            // Macro summary
            macroSummary

            // Add food button
            PrimaryButton(
                title: "Add Food",
                systemImage: "plus"
            ) {
                onAddFood()
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.lg)
    }

    private var macroSummary: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            macroItem(
                label: "Protein",
                value: totals.protein,
                unit: "g",
                color: AppTheme.Colors.protein
            )

            macroItem(
                label: "Fat",
                value: totals.fat,
                unit: "g",
                color: AppTheme.Colors.fat
            )

            macroItem(
                label: "Carbs",
                value: totals.carbs,
                unit: "g",
                color: AppTheme.Colors.carbs
            )
        }
    }

    private func macroItem(label: String, value: Double, unit: String, color: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(.secondary)

            Text("\(Int(value.rounded()))")
                .font(AppTheme.Typography.headline)
                .foregroundColor(color)

            Text(unit)
                .font(AppTheme.Typography.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TodaySummaryView(
            totals: DayTotals(
                calories: 1_200,
                protein: 45,
                fat: 30,
                carbs: 120
            )
        ) {}

        TodaySummaryView(
            totals: DayTotals(
                calories: 2_000,
                protein: 80,
                fat: 60,
                carbs: 200
            )
        ) {}
    }
    .padding()
}
