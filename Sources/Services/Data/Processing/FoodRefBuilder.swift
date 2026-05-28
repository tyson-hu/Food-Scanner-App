//
//  FoodRefBuilder.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

/// Service for converting FoodCard/FoodDetails to FoodRef
public struct FoodRefBuilder: Sendable {
    /// Convert FoodCard to FoodRef
    public static func from(foodCard: FoodCard) -> FoodRef {
        let gid = foodCard.id
        let source = foodCard.provenance.source

        return FoodRef(
            gid: gid,
            source: source,
            name: foodCard.description ?? "Unknown Food",
            brand: foodCard.brand,
            servingSize: foodCard.serving?.amount,
            servingSizeUnit: foodCard.serving?.unit,
            gramsPerServing: calculateGramsPerServing(from: foodCard.serving, baseUnit: foodCard.baseUnit),
            householdUnits: extractHouseholdUnits(from: foodCard.portions),
            foodLoggingNutrients: extractNutrients(from: foodCard.per100Base)
        )
    }

    /// Convert FoodDetails to FoodRef
    public static func from(foodDetails: FoodDetails) -> FoodRef {
        let gid = foodDetails.id
        let source = foodDetails.provenance.source

        return FoodRef(
            gid: gid,
            source: source,
            name: foodDetails.description ?? "Unknown Food",
            brand: foodDetails.brand,
            servingSize: foodDetails.serving?.amount,
            servingSizeUnit: foodDetails.serving?.unit,
            gramsPerServing: calculateGramsPerServing(from: foodDetails.serving, baseUnit: foodDetails.baseUnit),
            householdUnits: extractHouseholdUnits(from: foodDetails.portions),
            foodLoggingNutrients: extractNutrients(from: foodDetails.per100Base)
        )
    }

    // MARK: - Helper Functions

    /// Calculate grams per serving from serving info and base unit
    private static func calculateGramsPerServing(from serving: FoodServing?, baseUnit: BaseUnit) -> Double? {
        guard let serving,
              let amount = serving.amount else { return nil }

        switch baseUnit {
        case .grams:
            return amount
        case .milliliters:
            // For volume-based foods, we'd need density to convert to grams
            // For now, return nil as we don't have density in serving info
            return nil
        }
    }

    /// Extract household units from portions, filtering out invalid ones
    private static func extractHouseholdUnits(from portions: [FoodPortion]?) -> [HouseholdUnit]? {
        guard let portions, !portions.isEmpty else { return nil }

        let validUnits = portions.compactMap { portion -> HouseholdUnit? in
            guard let grams = portion.massG, grams > 0 else { return nil }
            return HouseholdUnit(label: portion.label, grams: grams)
        }

        return validUnits.isEmpty ? nil : validUnits
    }

    /// Extract nutrients from FoodNutrient array and convert to FoodLoggingNutrients
    private static func extractNutrients(from nutrients: [FoodNutrient]) -> FoodLoggingNutrients? {
        guard !nutrients.isEmpty else { return nil }

        return FoodLoggingNutrients(
            energyKcal: findNutrientValue(nutrients, name: "Energy", unit: "kcal"),
            protein: findNutrientValue(nutrients, name: "Protein", unit: "g"),
            fat: findNutrientValue(nutrients, name: "Total lipid (fat)", unit: "g"),
            saturatedFat: findNutrientValue(nutrients, name: "Fatty acids, total saturated", unit: "g"),
            carbs: findNutrientValue(nutrients, name: "Carbohydrate, by difference", unit: "g"),
            fiber: findNutrientValue(nutrients, name: "Fiber, total dietary", unit: "g"),
            sugars: findNutrientValue(nutrients, name: "Sugars, total including NLEA", unit: "g"),
            addedSugars: findNutrientValue(nutrients, name: "Added Sugars", unit: "g"),
            sodium: findNutrientValue(nutrients, name: "Sodium, Na", unit: "mg"),
            cholesterol: findNutrientValue(nutrients, name: "Cholesterol", unit: "mg")
        )
    }

    /// Find a specific nutrient value by name and unit
    private static func findNutrientValue(_ nutrients: [FoodNutrient], name: String, unit: String) -> Double? {
        nutrients.first { nutrient in
            nutrient.name.lowercased().contains(name.lowercased()) &&
                nutrient.unit.lowercased() == unit.lowercased()
        }?.amount
    }
}
