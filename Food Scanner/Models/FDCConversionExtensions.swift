//
//  FDCConversionExtensions.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//  Refactored from FDCModels.swift for better organization
//

import Foundation

// MARK: - Conversion Extensions

// Helper struct for nutrient parsing
private struct NutrientValues {
    var calories: Double = 0
    var protein: Double = 0
    var fat: Double = 0
    var carbs: Double = 0

    mutating func parseNutrient(id: Int, amount: Double) {
        switch id {
        case 1008: // Energy (kcal) - primary energy nutrient
            calories = amount
        case 2047, 2048: // Energy (Atwater General Factors or Specific Factors) - fallback
            if calories == 0 {
                calories = amount
            }
        case 1002: // Nitrogen - convert to protein (multiply by 6.25)
            protein = amount * 6.25
        case 1003: // Protein (if directly available)
            protein = amount
        case 1004: // Total lipid (fat)
            fat = amount
        case 1005: // Carbohydrate, by difference
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

extension ProxyFoodItem {
    func toFDCFoodSummary() -> FDCFoodSummary {
        // Map fields according to the issue specification
        let brand = brandOwner ?? brandName ?? ""
        let serving: String? = if let servingSize, let servingSizeUnit {
            "\(Int(servingSize)) \(servingSizeUnit)"
        } else {
            householdServingFullText
        }

        return FDCFoodSummary(
            id: fdcId,
            name: description.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.isEmpty ? nil : brand,
            serving: serving,
            upc: gtinUpc,
            publishedDate: publishedDate,
            modifiedDate: modifiedDate
        )
    }

    func toFDCFoodDetails() -> FDCFoodDetails {
        var nutrientValues = NutrientValues()

        // Parse nutrients from foodNutrients array
        if let nutrients = foodNutrients {
            for nutrient in nutrients {
                guard let nutrientId = nutrient.nutrient?.id,
                      let amount = nutrient.amount else { continue }
                nutrientValues.parseNutrient(id: nutrientId, amount: amount)
            }
        }

        let brand = brandOwner ?? brandName ?? ""

        return FDCFoodDetails(
            id: fdcId,
            name: description.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.isEmpty ? nil : brand,
            calories: Int(nutrientValues.calories),
            protein: Int(nutrientValues.protein),
            fat: Int(nutrientValues.fat),
            carbs: Int(nutrientValues.carbs)
        )
    }
}

// Conversion extension for ProxyFoodDetailResponse
extension ProxyFoodDetailResponse {
    func toFDCFoodDetails() -> FDCFoodDetails {
        var nutrientValues = NutrientValues()

        // Parse nutrients from foodNutrients array
        if let nutrients = foodNutrients {
            for nutrient in nutrients {
                guard let nutrientId = nutrient.nutrient?.id,
                      let amount = nutrient.amount else { continue }
                nutrientValues.parseNutrient(id: nutrientId, amount: amount)
            }
        }

        // Fallback to label nutrients if foodNutrients are missing or incomplete
        nutrientValues.parseLabelNutrients(labelNutrients)

        let brand = brandOwner ?? brandName ?? ""

        return FDCFoodDetails(
            id: fdcId,
            name: description.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.isEmpty ? nil : brand,
            calories: Int(nutrientValues.calories),
            protein: Int(nutrientValues.protein),
            fat: Int(nutrientValues.fat),
            carbs: Int(nutrientValues.carbs)
        )
    }
}

// Legacy conversion for backward compatibility
extension FDCFoodItem {
    func toFDCFoodSummary() -> FDCFoodSummary {
        FDCFoodSummary(
            id: fdcId,
            name: description,
            brand: brandOwner,
            serving: nil,
            upc: nil,
            publishedDate: nil,
            modifiedDate: nil
        )
    }

    func toFDCFoodDetails() -> FDCFoodDetails {
        let calories = foodNutrients.first { $0.nutrient.id == 1008 }?.amount ?? 0
        let protein = foodNutrients.first { $0.nutrient.id == 1003 }?.amount ?? 0
        let fat = foodNutrients.first { $0.nutrient.id == 1004 }?.amount ?? 0
        let carbs = foodNutrients.first { $0.nutrient.id == 1005 }?.amount ?? 0

        return FDCFoodDetails(
            id: fdcId,
            name: description,
            brand: brandOwner,
            calories: Int(calories),
            protein: Int(protein),
            fat: Int(fat),
            carbs: Int(carbs)
        )
    }
}
