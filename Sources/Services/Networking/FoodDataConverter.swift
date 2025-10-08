//
//  FoodDataConverter.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - Food Data Converter

public struct FoodDataConverter {
    public init() {}

    // MARK: - Conversion Helpers

    func convertToFoodServing(_ serving: NormalizedServing?) -> FoodServing? {
        guard let serving else { return nil }

        return FoodServing(
            amount: serving.amount,
            unit: serving.unit,
            household: serving.household
        )
    }

    func convertToFoodPortion(_ portion: NormalizedPortion) -> FoodPortion {
        // Create a meaningful label based on the portion type
        let meaningfulLabel = if let massG = portion.massG, massG == 100 {
            "100g portion"
        } else if let volMl = portion.volMl {
            "\(Int(volMl))ml portion"
        } else if let massG = portion.massG {
            "\(Int(massG))g portion"
        } else {
            "1 portion"
        }

        return FoodPortion(
            label: meaningfulLabel,
            amount: nil, // Not available in legacy model
            unit: nil, // Not available in legacy model
            household: portion.label, // Keep the original detailed label as household
            massG: portion.massG,
            volMl: portion.volMl
        )
    }

    func convertToFoodNutrient(_ nutrient: NormalizedNutrient) -> FoodNutrient {
        FoodNutrient(
            id: nutrient.id,
            name: nutrient.name,
            unit: nutrient.unit,
            amount: nutrient.amount,
            basis: nutrient.basis
        )
    }

    func convertToLegacyFoodNutrient(_ nutrient: NormalizedNutrient) -> FoodNutrient? {
        // This would need to map to the legacy FoodNutrient type
        // For now, return nil as this is a complex conversion
        nil
    }

    func convertToSourceTag(_ source: FoodSource) -> SourceTag {
        switch source {
        case .fdc:
            .fdc
        case .off:
            .off
        }
    }

    // MARK: - Conversion to public models

    func convertToFoodCard(_ normalizedFood: NormalizedFood) -> FoodCard {
        FoodCard(
            id: normalizedFood.gid,
            kind: normalizedFood.kind,
            code: normalizedFood.barcode,
            description: normalizedFood.primaryName,
            brand: normalizedFood.brand,
            baseUnit: normalizedFood.baseUnit,
            per100Base: normalizedFood.per100Base.map { convertToFoodNutrient($0) },
            serving: convertToFoodServing(normalizedFood.serving),
            portions: normalizedFood.portions.map { convertToFoodPortion($0) },
            densityGPerMl: normalizedFood.densityGPerMl,
            nutrients: normalizedFood.nutrients.map { convertToFoodNutrient($0) },
            provenance: FoodProvenance(
                source: convertToSourceTag(normalizedFood.source),
                id: normalizedFood.gid,
                fetchedAt: normalizedFood.fetchedAt
            )
        )
    }

    func convertToFoodDetails(_ normalizedFood: NormalizedFood) -> FoodDetails {
        FoodDetails(
            id: normalizedFood.gid,
            kind: normalizedFood.kind,
            code: normalizedFood.barcode,
            description: normalizedFood.primaryName,
            brand: normalizedFood.brand,
            ingredientsText: normalizedFood.ingredientsText,
            baseUnit: normalizedFood.baseUnit,
            per100Base: normalizedFood.per100Base.map { convertToFoodNutrient($0) },
            serving: convertToFoodServing(normalizedFood.serving),
            portions: normalizedFood.portions.map { convertToFoodPortion($0) },
            densityGPerMl: normalizedFood.densityGPerMl,
            nutrients: normalizedFood.nutrients.map { convertToFoodNutrient($0) },
            provenance: FoodProvenance(
                source: convertToSourceTag(normalizedFood.source),
                id: normalizedFood.gid,
                fetchedAt: normalizedFood.fetchedAt
            )
        )
    }

    func convertToFDCFoodSummary(_ foodCard: FoodCard) -> FDCFoodSummary {
        FDCFoodSummary(
            id: extractFDCId(from: foodCard.id),
            name: foodCard.description ?? "Unknown Food",
            brand: foodCard.brand,
            serving: foodCard.serving?.household,
            upc: foodCard.code,
            publishedDate: nil,
            modifiedDate: nil,
            dataType: foodCard.kind.rawValue,
            brandOwner: foodCard.brand,
            brandName: foodCard.brand,
            servingSize: foodCard.serving?.amount,
            servingSizeUnit: foodCard.serving?.unit,
            householdServingFullText: foodCard.serving?.household,
            packageWeight: nil,
            foodCategory: nil,
            foodCategoryId: nil,
            ingredients: nil,
            marketCountry: nil,
            tradeChannels: nil,
            calories: findNutrientValue(foodCard.nutrients, names: ["Energy", "Calories"]),
            protein: findNutrientValue(foodCard.nutrients, names: ["Protein"]),
            fat: findNutrientValue(foodCard.nutrients, names: ["Total lipid (fat)", "Fat"]),
            saturatedFat: findNutrientValue(foodCard.nutrients, names: ["Fatty acids, total saturated"]),
            transFat: findNutrientValue(foodCard.nutrients, names: ["Fatty acids, total trans"]),
            cholesterol: findNutrientValue(foodCard.nutrients, names: ["Cholesterol"]),
            sodium: findNutrientValue(foodCard.nutrients, names: ["Sodium, Na"]),
            carbohydrates: findNutrientValue(foodCard.nutrients, names: ["Carbohydrate, by difference"]),
            fiber: findNutrientValue(foodCard.nutrients, names: ["Fiber, total dietary"]),
            sugars: findNutrientValue(foodCard.nutrients, names: ["Sugars, total including NLEA"]),
            calcium: findNutrientValue(foodCard.nutrients, names: ["Calcium, Ca"]),
            iron: findNutrientValue(foodCard.nutrients, names: ["Iron, Fe"]),
            potassium: findNutrientValue(foodCard.nutrients, names: ["Potassium, K"]),
            macroSummary: createMacroSummary(from: foodCard.nutrients)
        )
    }

    func convertToFDCFoodDetails(_ normalizedFood: NormalizedFood) -> FDCFoodDetails {
        let publicNutrients = normalizedFood.nutrients.map { convertToFoodNutrient($0) }

        return FDCFoodDetails(
            id: extractFDCId(from: normalizedFood.gid),
            name: normalizedFood.primaryName,
            brand: normalizedFood.brand,
            calories: Int(findNutrientValue(publicNutrients, names: ["Energy", "Calories"]) ?? 0),
            protein: Int(findNutrientValue(publicNutrients, names: ["Protein"]) ?? 0),
            fat: Int(findNutrientValue(publicNutrients, names: ["Total lipid (fat)", "Fat"]) ?? 0),
            carbs: Int(findNutrientValue(publicNutrients, names: ["Carbohydrate, by difference"]) ?? 0),
            dataType: normalizedFood.source.rawValue,
            brandOwner: normalizedFood.brand,
            brandName: normalizedFood.brand,
            servingSize: normalizedFood.serving?.amount,
            servingSizeUnit: normalizedFood.serving?.unit,
            householdServingFullText: normalizedFood.serving?.household,
            packageWeight: nil,
            foodCategory: nil,
            foodCategoryId: nil,
            ingredients: normalizedFood.ingredientsText,
            marketCountry: nil,
            tradeChannels: nil,
            publishedDate: nil,
            modifiedDate: nil,
            gtinUpc: normalizedFood.barcode,
            labelNutrients: createLabelNutrients(from: publicNutrients),
            foodNutrients: normalizedFood.nutrients.compactMap { convertToLegacyFoodNutrient($0) }
        )
    }

    // MARK: - Helper Functions

    private func extractFDCId(from gid: String) -> Int {
        if gid.hasPrefix("fdc:") {
            return Int(String(gid.dropFirst(4))) ?? 0
        }
        return 0
    }

    private func findNutrientValue(_ nutrients: [FoodNutrient], names: [String]) -> Double? {
        for nutrient in nutrients where names.contains(where: { name in
            nutrient.name.lowercased().contains(name.lowercased())
        }) {
            return nutrient.amount
        }
        return nil
    }

    private func createMacroSummary(from nutrients: [FoodNutrient]) -> MacroSummary? {
        let calories = findNutrientValue(nutrients, names: ["Energy", "Calories"]) ?? 0
        let protein = findNutrientValue(nutrients, names: ["Protein"]) ?? 0
        let fat = findNutrientValue(nutrients, names: ["Total lipid (fat)", "Fat"]) ?? 0
        let carbs = findNutrientValue(nutrients, names: ["Carbohydrate, by difference"]) ?? 0
        let fiber = findNutrientValue(nutrients, names: ["Fiber, total dietary"])
        let sugars = findNutrientValue(nutrients, names: ["Sugars, total including NLEA"])

        return MacroSummary(
            calories: calories,
            protein: protein,
            fat: fat,
            carbohydrates: carbs,
            fiber: fiber,
            sugars: sugars
        )
    }

    private func createLabelNutrients(from nutrients: [FoodNutrient]) -> LabelNutrients? {
        // This would create a LabelNutrients object from the normalized nutrients
        // For now, return nil as this is a complex conversion
        nil
    }
}
