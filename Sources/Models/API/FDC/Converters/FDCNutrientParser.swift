//
//  FDCNutrientParser.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/30/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - FDC Nutrient Parser

public struct FDCNutrientParser {
    public init() {}

    // Helper struct for nutrient parsing
    public struct NutrientValues {
        var calories: Double = 0
        var protein: Double = 0
        var fat: Double = 0
        var carbs: Double = 0

        mutating func parseNutrient(id: Int, amount: Double) {
            switch id {
            case 1_008: // Energy (kcal) - primary energy nutrient
                calories = amount
            case 2_047, 2_048: // Energy (Atwater General Factors or Specific Factors) - fallback
                if calories == 0 {
                    calories = amount
                }
            case 1_002: // Nitrogen - convert to protein (multiply by 6.25)
                protein = amount * 6.25
            case 1_003: // Protein (if directly available)
                protein = amount
            case 1_004: // Total lipid (fat)
                fat = amount
            case 1_005: // Carbohydrate, by difference
                carbs = amount
            default:
                break
            }
        }

        mutating func parseLabelNutrients(_ labelNutrients: ProxyLabelNutrients?) {
            guard let labelNutrients else { return }

            // Only use label nutrients if we don't already have values from foodNutrients
            if calories == 0, let caloriesValue = labelNutrients.calories?.value {
                calories = caloriesValue
            }
            if protein == 0, let proteinValue = labelNutrients.protein?.value {
                protein = proteinValue
            }
            if fat == 0, let fatValue = labelNutrients.fat?.value {
                fat = fatValue
            }
            if carbs == 0, let carbsValue = labelNutrients.carbohydrates?.value {
                carbs = carbsValue
            }
        }
    }

    public func parseNutrients(from proxyResponse: ProxyFoodDetailResponse) -> NutrientValues {
        var nutrientValues = NutrientValues()

        // Parse nutrients from foodNutrients array
        if let nutrients = proxyResponse.foodNutrients {
            for nutrient in nutrients {
                guard let nutrientId = nutrient.nutrient?.id,
                      let amount = nutrient.amount else { continue }
                nutrientValues.parseNutrient(id: nutrientId, amount: amount)
            }
        }

        // Fallback to label nutrients if foodNutrients are missing or incomplete
        nutrientValues.parseLabelNutrients(proxyResponse.labelNutrients)

        return nutrientValues
    }
}
