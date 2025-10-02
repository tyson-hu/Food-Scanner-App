//
//  LoggedFoodEntry.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import SwiftData

@Model
public final class FoodEntry {
    // Persistent fields
    public var id = UUID()
    var date = Date()
    var name: String
    var brand: String?
    var fdcId: Int?
    var quantity: Double = 1.0
    var unit: String = "serving" // g, ml, serving, can, cup, etc.
    var servingDescription: String = "1 serving"
    var resolvedToBase: Double = 100.0 // quantity expressed in baseUnit at log time
    var baseUnit: String = "g" // "g" or "ml" - the food's base unit
    var calories: Double = 0.0
    var protein: Double = 0.0
    var fat: Double = 0.0
    var carbs: Double = 0.0
    var nutrientsSnapshot: [String: Double] = [:] // totals computed at log time

    init(
        name: String,
        calories: Double,
        protein: Double,
        fat: Double,
        carbs: Double,
        brand: String? = nil,
        fdcId: Int? = nil,
        quantity: Double = 1,
        unit: String = "serving",
        servingDescription: String = "1 serving",
        resolvedToBase: Double = 100.0,
        baseUnit: String = "g",
        nutrientsSnapshot: [String: Double] = [:]
    ) {
        self.name = name
        self.brand = brand
        self.fdcId = fdcId
        self.quantity = quantity
        self.unit = unit
        self.servingDescription = servingDescription
        self.resolvedToBase = resolvedToBase
        self.baseUnit = baseUnit
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.nutrientsSnapshot = nutrientsSnapshot
    }
}

// MARK: - Builder Extensions

extension FoodEntry {
    nonisolated static func from(
        details foodDetails: FDCFoodDetails,
        multiplier servingMultiplier: Double,
        at date: Date = .now
    ) -> FoodEntry {
        FoodEntryBuilder.from(details: foodDetails, multiplier: servingMultiplier, at: date)
    }

    nonisolated static func from(
        foodCard: FoodMinimalCard,
        multiplier servingMultiplier: Double,
        at date: Date = .now
    ) -> FoodEntry {
        FoodEntryBuilder.from(foodCard: foodCard, multiplier: servingMultiplier, at: date)
    }

    nonisolated static func from(
        foodDetails: FoodAuthoritativeDetail,
        multiplier servingMultiplier: Double,
        at date: Date = .now
    ) -> FoodEntry {
        FoodEntryBuilder.from(foodDetails: foodDetails, multiplier: servingMultiplier, at: date)
    }

    // tiny helper to assign date inline
    func withDate(_ date: Date) -> FoodEntry {
        self.date = date
        return self
    }
}
