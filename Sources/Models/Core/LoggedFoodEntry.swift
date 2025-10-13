//
//  LoggedFoodEntry.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import SwiftData

@Model
public final class FoodEntry {
    // Existing fields (keep for backward compatibility)
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

    // NEW FIELDS FOR 0.4.0
    public var kind = EntryKind.catalog
    public var foodGID: String? // Link to FoodRef
    public var customName: String? // For manual entries
    public var meal = Meal.lunch // Default meal
    public var gramsResolved: Double? // Actual grams when known
    public var note: String? // Optional user note

    // Snapshot nutrients (optionals: nil = missing, not zero)
    public var snapEnergyKcal: Double?
    public var snapProtein: Double?
    public var snapFat: Double?
    public var snapSaturatedFat: Double?
    public var snapCarbs: Double?
    public var snapFiber: Double?
    public var snapSugars: Double?
    public var snapAddedSugars: Double?
    public var snapSodium: Double?
    public var snapCholesterol: Double?

    // Keep existing init for backward compatibility
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

        // Initialize new fields with defaults
        kind = .catalog
        foodGID = nil
        customName = nil
        meal = .lunch
        gramsResolved = nil
        note = nil

        // Initialize snapshot nutrients with defaults
        snapEnergyKcal = nil
        snapProtein = nil
        snapFat = nil
        snapSaturatedFat = nil
        snapCarbs = nil
        snapFiber = nil
        snapSugars = nil
        snapAddedSugars = nil
        snapSodium = nil
        snapCholesterol = nil
    }

    // New enhanced initializer for 0.4.0
    public init(
        kind: EntryKind,
        name: String,
        meal: Meal = .lunch,
        quantity: Double = 1.0,
        unit: String = "serving",
        foodGID: String? = nil,
        customName: String? = nil,
        gramsResolved: Double? = nil,
        note: String? = nil,
        // Snapshot nutrients
        snapEnergyKcal: Double? = nil,
        snapProtein: Double? = nil,
        snapFat: Double? = nil,
        snapSaturatedFat: Double? = nil,
        snapCarbs: Double? = nil,
        snapFiber: Double? = nil,
        snapSugars: Double? = nil,
        snapAddedSugars: Double? = nil,
        snapSodium: Double? = nil,
        snapCholesterol: Double? = nil,
        // Legacy fields for compatibility
        brand: String? = nil,
        fdcId: Int? = nil,
        servingDescription: String = "1 serving",
        resolvedToBase: Double = 100.0,
        baseUnit: String = "g",
        calories: Double = 0.0,
        protein: Double = 0.0,
        fat: Double = 0.0,
        carbs: Double = 0.0,
        nutrientsSnapshot: [String: Double] = [:]
    ) {
        self.kind = kind
        self.name = name
        self.meal = meal
        self.quantity = quantity
        self.unit = unit
        self.foodGID = foodGID
        self.customName = customName
        self.gramsResolved = gramsResolved
        self.note = note

        // Snapshot nutrients
        self.snapEnergyKcal = snapEnergyKcal
        self.snapProtein = snapProtein
        self.snapFat = snapFat
        self.snapSaturatedFat = snapSaturatedFat
        self.snapCarbs = snapCarbs
        self.snapFiber = snapFiber
        self.snapSugars = snapSugars
        self.snapAddedSugars = snapAddedSugars
        self.snapSodium = snapSodium
        self.snapCholesterol = snapCholesterol

        // Legacy fields
        self.brand = brand
        self.fdcId = fdcId
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
        foodCard: FoodCard,
        multiplier servingMultiplier: Double,
        at date: Date = .now
    ) -> FoodEntry {
        FoodEntryBuilder.from(foodCard: foodCard, multiplier: servingMultiplier, at: date)
    }

    nonisolated static func from(
        foodDetails: FoodDetails,
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
