//
//  LoggedFoodEntryBuilder.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - Food Entry Builder

public struct FoodEntryBuilder {
    public init() {}

    // MARK: - Builder from FDC details

    public nonisolated static func from(
        details foodDetails: FDCFoodDetails,
        multiplier servingMultiplier: Double,
        at date: Date = .now
    ) -> FoodEntry {
        // Determine base unit based on serving size unit
        let baseUnit = determineBaseUnit(from: foodDetails.servingSizeUnit)

        // Calculate resolved quantity in base unit
        let resolvedToBase = calculateResolvedQuantity(
            quantity: servingMultiplier,
            servingSize: foodDetails.servingSize,
            servingSizeUnit: foodDetails.servingSizeUnit,
            baseUnit: baseUnit
        )

        // Create nutrients snapshot
        let nutrientsSnapshot = [
            "calories": Double(foodDetails.calories) * servingMultiplier,
            "protein": Double(foodDetails.protein) * servingMultiplier,
            "fat": Double(foodDetails.fat) * servingMultiplier,
            "carbs": Double(foodDetails.carbs) * servingMultiplier
        ]

        return FoodEntry(
            name: foodDetails.name,
            calories: Double(foodDetails.calories) * servingMultiplier,
            protein: Double(foodDetails.protein) * servingMultiplier,
            fat: Double(foodDetails.fat) * servingMultiplier,
            carbs: Double(foodDetails.carbs) * servingMultiplier,
            brand: foodDetails.brand,
            fdcId: foodDetails.id,
            quantity: servingMultiplier,
            unit: "serving",
            servingDescription: String(format: "%.2f× serving", servingMultiplier),
            resolvedToBase: resolvedToBase,
            baseUnit: baseUnit,
            nutrientsSnapshot: nutrientsSnapshot
        ).withDate(date)
    }

    // MARK: - Builder from FoodRef (NEW)

    public static func from(
        foodRef: FoodRef,
        quantity: Double,
        unit: Unit,
        meal: Meal,
        at date: Date = .now
    ) async -> FoodEntry {
        // Extract nutrients from FoodRef
        let nutrients: FoodLoggingNutrients = if let existingNutrients = foodRef.foodLoggingNutrients {
            existingNutrients
        } else {
            FoodLoggingNutrients()
        }

        // Calculate snapshot nutrients using SnapshotNutrientCalculator
        let params = SnapshotNutrientCalculator.CalculationParams(
            quantity: quantity,
            unit: unit,
            gramsPerServing: foodRef.gramsPerServing,
            densityGPerMl: nil, // FoodRef doesn't store density
            householdUnits: foodRef.householdUnits
        )
        let snapshotNutrients = SnapshotNutrientCalculator.calculateSnapshot(
            per100Nutrients: nutrients,
            params: params
        )

        // Convert snapshot nutrients to legacy format for backward compatibility
        let nutrientsSnapshot = [
            "calories": snapshotNutrients.energyKcal,
            "protein": snapshotNutrients.protein,
            "fat": snapshotNutrients.fat,
            "carbs": snapshotNutrients.carbs,
            "fiber": snapshotNutrients.fiber,
            "sugars": snapshotNutrients.sugars,
            "sodium": snapshotNutrients.sodium,
            "cholesterol": snapshotNutrients.cholesterol
        ].compactMapValues { $0 }

        // Calculate resolved quantity using PortionResolver
        let resolvedGrams = PortionResolver.resolveToGrams(
            quantity: quantity,
            unit: unit,
            gramsPerServing: foodRef.gramsPerServing,
            densityGPerMl: nil,
            householdUnits: foodRef.householdUnits
        ) ?? quantity * 100.0 // Fallback to 100g per serving

        return FoodEntry(
            kind: .catalog,
            name: foodRef.name,
            meal: meal,
            quantity: quantity,
            unit: unit.displayName,
            foodGID: foodRef.gid,
            customName: nil,
            gramsResolved: resolvedGrams,
            note: nil,
            snapEnergyKcal: snapshotNutrients.energyKcal,
            snapProtein: snapshotNutrients.protein,
            snapFat: snapshotNutrients.fat,
            snapSaturatedFat: snapshotNutrients.saturatedFat,
            snapCarbs: snapshotNutrients.carbs,
            snapFiber: snapshotNutrients.fiber,
            snapSugars: snapshotNutrients.sugars,
            snapSodium: snapshotNutrients.sodium,
            snapCholesterol: snapshotNutrients.cholesterol,
            brand: foodRef.brand,
            fdcId: extractFdcId(from: foodRef.gid),
            servingDescription: formatServingDescription(quantity: quantity, unit: unit),
            resolvedToBase: resolvedGrams,
            baseUnit: "g", // Always resolve to grams
            calories: snapshotNutrients.energyKcal ?? 0.0,
            protein: snapshotNutrients.protein ?? 0.0,
            fat: snapshotNutrients.fat ?? 0.0,
            carbs: snapshotNutrients.carbs ?? 0.0,
            nutrientsSnapshot: nutrientsSnapshot
        ).withDate(date)
    }

    // MARK: - Manual Entry Builder (NEW)

    public nonisolated static func manual(
        name: String,
        energyKcal: Double,
        meal: Meal,
        protein: Double? = nil,
        fat: Double? = nil,
        carbs: Double? = nil,
        at date: Date = .now
    ) -> FoodEntry {
        // Create nutrients snapshot for manual entry
        let nutrientsSnapshot = [
            "calories": energyKcal,
            "protein": protein,
            "fat": fat,
            "carbs": carbs
        ].compactMapValues { $0 }

        return FoodEntry(
            kind: .manual,
            name: name,
            meal: meal,
            quantity: 1.0,
            unit: "serving",
            foodGID: nil,
            customName: name,
            gramsResolved: 100.0,
            note: nil,
            snapEnergyKcal: energyKcal,
            snapProtein: protein,
            snapFat: fat,
            snapSaturatedFat: nil,
            snapCarbs: carbs,
            snapFiber: nil,
            snapSugars: nil,
            snapSodium: nil,
            snapCholesterol: nil,
            brand: nil,
            fdcId: nil,
            servingDescription: "1× serving",
            resolvedToBase: 100.0, // Default to 100g
            baseUnit: "g",
            calories: energyKcal,
            protein: protein ?? 0.0,
            fat: fat ?? 0.0,
            carbs: carbs ?? 0.0,
            nutrientsSnapshot: nutrientsSnapshot
        ).withDate(date)
    }

    // MARK: - Builder from new API models (EXISTING - kept for backward compatibility)

    public nonisolated static func from(
        foodCard: FoodCard,
        multiplier servingMultiplier: Double,
        at date: Date = .now
    ) -> FoodEntry {
        // Extract FDC ID from GID if possible
        let fdcId: Int? = {
            if foodCard.id.hasPrefix("fdc:"), let id = Int(foodCard.id.dropFirst(4)) {
                return id
            }
            return nil
        }()

        // Use the new per100Base nutrients (preferred) or fallback to legacy nutrients
        let nutrientsToUse = foodCard.per100Base.isEmpty ? foodCard.nutrients : foodCard.per100Base

        // Calculate basic nutrients from the card
        let calories = calculateNutrientValue(nutrients: nutrientsToUse, name: "Energy", unit: "kcal") ?? 0.0
        let protein = calculateNutrientValue(nutrients: nutrientsToUse, name: "Protein", unit: "g") ?? 0.0
        let fat = calculateNutrientValue(nutrients: nutrientsToUse, name: "Total lipid (fat)", unit: "g") ?? 0.0
        let carbs = calculateNutrientValue(
            nutrients: nutrientsToUse,
            name: "Carbohydrate, by difference",
            unit: "g"
        ) ?? 0.0

        // Calculate resolved quantity in base unit
        let resolvedToBase = calculateResolvedQuantity(
            quantity: servingMultiplier,
            serving: foodCard.serving,
            baseUnit: foodCard.baseUnit
        )

        // Calculate serving size ratio for nutrient scaling
        let servingSizeRatio = resolvedToBase / 100.0 // Convert from per-100-base to actual serving size

        // Create nutrients snapshot
        let nutrientsSnapshot = [
            "calories": calories * servingSizeRatio,
            "protein": protein * servingSizeRatio,
            "fat": fat * servingSizeRatio,
            "carbs": carbs * servingSizeRatio
        ]

        return FoodEntry(
            name: foodCard.description ?? "Unknown Food",
            calories: calories * servingSizeRatio,
            protein: protein * servingSizeRatio,
            fat: fat * servingSizeRatio,
            carbs: carbs * servingSizeRatio,
            brand: foodCard.brand,
            fdcId: fdcId,
            quantity: servingMultiplier,
            unit: "serving",
            servingDescription: formatServingDescription(foodCard.serving, multiplier: servingMultiplier),
            resolvedToBase: resolvedToBase,
            baseUnit: foodCard.baseUnit.rawValue,
            nutrientsSnapshot: nutrientsSnapshot
        ).withDate(date)
    }

    public nonisolated static func from(
        foodDetails: FoodDetails,
        multiplier servingMultiplier: Double,
        at date: Date = .now
    ) -> FoodEntry {
        // Extract FDC ID from GID if possible
        let fdcId: Int? = {
            if foodDetails.id.hasPrefix("fdc:"), let id = Int(foodDetails.id.dropFirst(4)) {
                return id
            }
            return nil
        }()

        // Use the new per100Base nutrients (preferred) or fallback to legacy nutrients
        let nutrientsToUse = foodDetails.per100Base.isEmpty ? foodDetails.nutrients : foodDetails.per100Base

        // Calculate basic nutrients from the details
        let calories = calculateNutrientValue(nutrients: nutrientsToUse, name: "Energy", unit: "kcal") ?? 0.0
        let protein = calculateNutrientValue(nutrients: nutrientsToUse, name: "Protein", unit: "g") ?? 0.0
        let fat = calculateNutrientValue(nutrients: nutrientsToUse, name: "Total lipid (fat)", unit: "g") ?? 0.0
        let carbs = calculateNutrientValue(
            nutrients: nutrientsToUse,
            name: "Carbohydrate, by difference",
            unit: "g"
        ) ?? 0.0

        // Calculate resolved quantity in base unit
        let resolvedToBase = calculateResolvedQuantity(
            quantity: servingMultiplier,
            serving: foodDetails.serving,
            baseUnit: foodDetails.baseUnit
        )

        // Create nutrients snapshot
        let nutrientsSnapshot = [
            "calories": calories * servingMultiplier,
            "protein": protein * servingMultiplier,
            "fat": fat * servingMultiplier,
            "carbs": carbs * servingMultiplier
        ]

        return FoodEntry(
            name: foodDetails.description ?? "Unknown Food",
            calories: calories * servingMultiplier,
            protein: protein * servingMultiplier,
            fat: fat * servingMultiplier,
            carbs: carbs * servingMultiplier,
            brand: foodDetails.brand,
            fdcId: fdcId,
            quantity: servingMultiplier,
            unit: "serving",
            servingDescription: formatServingDescription(foodDetails.serving, multiplier: servingMultiplier),
            resolvedToBase: resolvedToBase,
            baseUnit: foodDetails.baseUnit.rawValue,
            nutrientsSnapshot: nutrientsSnapshot
        ).withDate(date)
    }

    // MARK: - Helper Functions

    // Helper to extract FDC ID from GID
    private nonisolated static func extractFdcId(from gid: String) -> Int? {
        if gid.hasPrefix("fdc:"), let id = Int(gid.dropFirst(4)) {
            return id
        }
        return nil
    }

    // Helper to format serving description for new Unit enum
    private nonisolated static func formatServingDescription(quantity: Double, unit: Unit) -> String {
        switch unit {
        case .grams:
            return String(format: "%.2f g", quantity)
        case .milliliters:
            return String(format: "%.2f ml", quantity)
        case .serving:
            return String(format: "%.2f× serving", quantity)
        case let .household(label):
            return String(format: "%.2f× %@", quantity, label)
        }
    }

    // Helper to calculate nutrient values
    private nonisolated static func calculateNutrientValue(
        nutrients: [FoodNutrient],
        name: String,
        unit: String
    ) -> Double? {
        // Always prefer per-100g nutrients as the standard
        if let per100gNutrient = nutrients.first(where: { nutrient in
            nutrient.name.lowercased().contains(name.lowercased()) &&
                nutrient.unit.lowercased() == unit.lowercased() &&
                nutrient.basis == .per100g
        }) {
            return per100gNutrient.amount
        }

        // Fallback to per-serving if no per-100g found
        if let perServingNutrient = nutrients.first(where: { nutrient in
            nutrient.name.lowercased().contains(name.lowercased()) &&
                nutrient.unit.lowercased() == unit.lowercased() &&
                nutrient.basis == .perServing
        }) {
            return perServingNutrient.amount
        }

        // Last resort: any nutrient with matching name and unit
        return nutrients.first { nutrient in
            nutrient.name.lowercased().contains(name.lowercased()) &&
                nutrient.unit.lowercased() == unit.lowercased()
        }?.amount
    }

    // Helper to format serving description
    private nonisolated static func formatServingDescription(_ serving: FoodServing?, multiplier: Double) -> String {
        guard let serving else {
            return String(format: "%.2f× 100g", multiplier)
        }

        if let amount = serving.amount, let unit = serving.unit {
            return String(format: "%.2f× %.1f %@", multiplier, amount, unit)
        } else if let household = serving.household {
            return String(format: "%.2f× %@", multiplier, household)
        } else {
            return String(format: "%.2f× 100g", multiplier)
        }
    }

    // MARK: - Base Unit Helper Functions

    /// Determine base unit from serving size unit
    nonisolated static func determineBaseUnit(from servingSizeUnit: String?) -> String {
        guard let unit = servingSizeUnit?.lowercased() else { return "g" }

        // Volume units → ml
        if ["ml", "milliliter", "milliliters", "mlt", "l", "liter", "liters", "fl oz", "fluid ounce", "fluid ounces"]
            .contains(unit) {
            return "ml"
        }

        // Default to grams for mass units
        return "g"
    }

    /// Calculate resolved quantity in base unit
    nonisolated static func calculateResolvedQuantity(
        quantity: Double,
        servingSize: Double?,
        servingSizeUnit: String?,
        baseUnit: String
    ) -> Double {
        guard let servingSize, let servingSizeUnit else {
            return quantity * 100.0 // Default to 100g/ml per serving
        }

        let servingInBaseUnit = convertToBaseUnit(amount: servingSize, unit: servingSizeUnit, targetBaseUnit: baseUnit)
        return quantity * servingInBaseUnit
    }

    /// Calculate resolved quantity in base unit from serving info
    nonisolated static func calculateResolvedQuantity(
        quantity: Double,
        serving: FoodServing?,
        baseUnit: BaseUnit
    ) -> Double {
        guard let serving,
              let amount = serving.amount,
              let unit = serving.unit else {
            return quantity * 100.0 // Default to 100g/ml per serving
        }

        let servingInBaseUnit = convertToBaseUnit(amount: amount, unit: unit, targetBaseUnit: baseUnit.rawValue)
        return quantity * servingInBaseUnit
    }

    /// Convert amount from source unit to target base unit
    nonisolated static func convertToBaseUnit(amount: Double, unit: String, targetBaseUnit: String) -> Double {
        let grams = convertToGrams(amount: amount, unit: unit)
        return convertGramsToTargetUnit(grams: grams, targetBaseUnit: targetBaseUnit)
    }

    /// Convert amount to grams from various units
    private nonisolated static func convertToGrams(amount: Double, unit: String) -> Double {
        let unitLower = unit.lowercased()

        if let massConversion = convertMassToGrams(amount: amount, unit: unitLower) {
            return massConversion
        }

        if let volumeConversion = convertVolumeToGrams(amount: amount, unit: unitLower) {
            return volumeConversion
        }

        return amount // Default assumption
    }

    /// Convert mass units to grams
    private nonisolated static func convertMassToGrams(amount: Double, unit: String) -> Double? {
        switch unit {
        case "g", "gram", "grams":
            amount
        case "kg", "kilogram", "kilograms":
            amount * 1_000
        case "oz", "ounce", "ounces":
            amount * 28.3495
        case "lb", "pound", "pounds":
            amount * 453.592
        default:
            nil
        }
    }

    /// Convert volume units to grams (approximate for water)
    private nonisolated static func convertVolumeToGrams(amount: Double, unit: String) -> Double? {
        switch unit {
        case "ml", "milliliter", "milliliters", "mlt":
            amount
        case "l", "liter", "liters":
            amount * 1_000
        case "fl oz", "fluid ounce", "fluid ounces":
            amount * 29.5735
        case "cup", "cups":
            amount * 240
        case "tbsp", "tablespoon", "tablespoons":
            amount * 15
        case "tsp", "teaspoon", "teaspoons":
            amount * 5
        default:
            nil
        }
    }

    /// Convert grams to target base unit
    private nonisolated static func convertGramsToTargetUnit(grams: Double, targetBaseUnit: String) -> Double {
        if targetBaseUnit == "ml" {
            grams // Approximate 1:1 for water
        } else {
            grams // Already in grams
        }
    }
}
