//
//  FoodEntry.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/17/25.
//

import Foundation
import SwiftData

@Model
final class FoodEntry {
    // Persistent fields
    var id = UUID()
    var date = Date()
    var name: String
    var brand: String?
    var fdcId: Int?
    var quantity: Double = 1.0
    var servingDescription: String = "1 serving"
    var calories: Double = 0.0
    var protein: Double = 0.0
    var fat: Double = 0.0
    var carbs: Double = 0.0

    init(
        name: String,
        brand: String? = nil,
        fdcId: Int? = nil,
        quantity: Double = 1,
        servingDescription: String = "1 serving",
        calories: Double,
        protein: Double,
        fat: Double,
        carbs: Double,
    ) {
        self.name = name
        self.brand = brand
        self.fdcId = fdcId
        self.quantity = quantity
        self.servingDescription = servingDescription
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
    }
}

// MARK: - Builder from FDC details

extension FoodEntry {
    static func from(
        details foodDetails: FDCFoodDetails,
        multiplier servingMultiplier: Double,
        at date: Date = Date(),
    ) -> FoodEntry {
        FoodEntry(
            name: foodDetails.name,
            brand: foodDetails.brand,
            fdcId: foodDetails.id,
            quantity: servingMultiplier,
            servingDescription: String(format: "%.2f× serving", servingMultiplier),
            calories: Double(foodDetails.calories) * servingMultiplier,
            protein: Double(foodDetails.protein) * servingMultiplier,
            fat: Double(foodDetails.fat) * servingMultiplier,
            carbs: Double(foodDetails.carbs) * servingMultiplier,
        ).withDate(date)
    }

    // MARK: - Builder from new API models

    static func from(
        foodCard: FoodMinimalCard,
        multiplier servingMultiplier: Double,
        at date: Date = Date(),
    ) -> FoodEntry {
        // Extract FDC ID from GID if possible
        let fdcId: Int? = {
            if foodCard.id.hasPrefix("fdc:"), let id = Int(foodCard.id.dropFirst(4)) {
                return id
            }
            return nil
        }()

        // Calculate basic nutrients from the card
        let calories = calculateNutrientValue(nutrients: foodCard.nutrients, name: "Energy", unit: "kcal") ?? 0.0
        let protein = calculateNutrientValue(nutrients: foodCard.nutrients, name: "Protein", unit: "g") ?? 0.0
        let fat = calculateNutrientValue(nutrients: foodCard.nutrients, name: "Total lipid (fat)", unit: "g") ?? 0.0
        let carbs = calculateNutrientValue(
            nutrients: foodCard.nutrients,
            name: "Carbohydrate, by difference",
            unit: "g",
        ) ?? 0.0

        return FoodEntry(
            name: foodCard.description ?? "Unknown Food",
            brand: foodCard.brand,
            fdcId: fdcId,
            quantity: servingMultiplier,
            servingDescription: formatServingDescription(foodCard.serving, multiplier: servingMultiplier),
            calories: calories * servingMultiplier,
            protein: protein * servingMultiplier,
            fat: fat * servingMultiplier,
            carbs: carbs * servingMultiplier,
        ).withDate(date)
    }

    static func from(
        foodDetails: FoodAuthoritativeDetail,
        multiplier servingMultiplier: Double,
        at date: Date = Date(),
    ) -> FoodEntry {
        // Extract FDC ID from GID if possible
        let fdcId: Int? = {
            if foodDetails.id.hasPrefix("fdc:"), let id = Int(foodDetails.id.dropFirst(4)) {
                return id
            }
            return nil
        }()

        // Calculate basic nutrients from the details
        let calories = calculateNutrientValue(nutrients: foodDetails.nutrients, name: "Energy", unit: "kcal") ?? 0.0
        let protein = calculateNutrientValue(nutrients: foodDetails.nutrients, name: "Protein", unit: "g") ?? 0.0
        let fat = calculateNutrientValue(nutrients: foodDetails.nutrients, name: "Total lipid (fat)", unit: "g") ?? 0.0
        let carbs = calculateNutrientValue(
            nutrients: foodDetails.nutrients,
            name: "Carbohydrate, by difference",
            unit: "g",
        ) ?? 0.0

        return FoodEntry(
            name: foodDetails.description ?? "Unknown Food",
            brand: foodDetails.brand,
            fdcId: fdcId,
            quantity: servingMultiplier,
            servingDescription: formatServingDescription(foodDetails.serving, multiplier: servingMultiplier),
            calories: calories * servingMultiplier,
            protein: protein * servingMultiplier,
            fat: fat * servingMultiplier,
            carbs: carbs * servingMultiplier,
        ).withDate(date)
    }

    // tiny helper to assign date inline
    private func withDate(_ date: Date) -> FoodEntry {
        self.date = date
        return self
    }

    // Helper to calculate nutrient values
    private static func calculateNutrientValue(nutrients: [FoodNutrient], name: String, unit: String) -> Double? {
        nutrients.first { nutrient in
            nutrient.name.lowercased().contains(name.lowercased()) &&
                nutrient.unit.lowercased() == unit.lowercased() &&
                nutrient.basis == .perServing
        }?.amount
    }

    // Helper to format serving description
    private static func formatServingDescription(_ serving: FoodServing?, multiplier: Double) -> String {
        guard let serving else {
            return String(format: "%.2f× serving", multiplier)
        }

        if let amount = serving.amount, let unit = serving.unit {
            return String(format: "%.2f× %.1f %@", multiplier, amount, unit)
        } else if let household = serving.household {
            return String(format: "%.2f× %@", multiplier, household)
        } else {
            return String(format: "%.2f× serving", multiplier)
        }
    }
}
