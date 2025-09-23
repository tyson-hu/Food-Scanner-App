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
    var id: UUID = UUID()
    var date: Date = Date()
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
        carbs: Double
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
        at date: Date = Date()
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
            carbs: Double(foodDetails.carbs) * servingMultiplier
        ).withDate(date)
    }

    // tiny helper to assign date inline
    private func withDate(_ date: Date) -> FoodEntry {
        self.date = date
        return self
    }
}
