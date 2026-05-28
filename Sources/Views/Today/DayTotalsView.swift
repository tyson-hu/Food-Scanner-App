//
//  DayTotalsView.swift
//  Calry
//
//  Created by Tyson Hu on 10/13/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftUI

struct DayTotalsView: View {
    let totals: DayTotals

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            SectionHeaderView(title: "Daily Totals")

            VStack(spacing: 8) {
                totalRow(label: "Calories", value: totals.calories, unit: "kcal", dvNutrient: "energy")
                totalRow(label: "Protein", value: totals.protein, unit: "g", dvNutrient: "protein")
                totalRow(label: "Fat", value: totals.fat, unit: "g", dvNutrient: "fat")
                if let saturatedFat = totals.saturatedFat {
                    totalRow(label: "Saturated Fat", value: saturatedFat, unit: "g", dvNutrient: "saturated fat")
                }
                totalRow(label: "Carbs", value: totals.carbs, unit: "g", dvNutrient: "carbs")
                if let fiber = totals.fiber {
                    totalRow(label: "Fiber", value: fiber, unit: "g", dvNutrient: "fiber")
                }
                if let sugars = totals.sugars {
                    totalRow(label: "Sugars", value: sugars, unit: "g", dvNutrient: nil)
                }
                if let addedSugars = totals.addedSugars {
                    totalRow(label: "Added Sugars", value: addedSugars, unit: "g", dvNutrient: "added sugars")
                }
                if let sodium = totals.sodium {
                    totalRow(label: "Sodium", value: sodium, unit: "mg", dvNutrient: "sodium")
                }
                if let cholesterol = totals.cholesterol {
                    totalRow(label: "Cholesterol", value: cholesterol, unit: "mg", dvNutrient: "cholesterol")
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.lg)
    }

    private func totalRow(label: String, value: Double, unit: String, dvNutrient: String?) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.body)

            Spacer()

            Text("\(String(format: "%.1f", value)) \(unit)")
                .font(AppTheme.Typography.headline)

            if let nutrient = dvNutrient,
               let percentDV = DVCalculator.percentDV(for: nutrient, amount: value) {
                Text("(\(Int(percentDV))% DV)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    DayTotalsView(totals: DayTotals(
        calories: 1_800,
        protein: 120,
        fat: 60,
        saturatedFat: 20,
        carbs: 150,
        fiber: 25,
        sugars: 30,
        addedSugars: 15,
        sodium: 2_000,
        cholesterol: 200
    ))
    .padding()
}
