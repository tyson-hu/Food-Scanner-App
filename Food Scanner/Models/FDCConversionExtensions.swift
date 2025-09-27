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

        // Extract label nutrients for quick glance
        let labelNutrients = extractLabelNutrients()

        // Extract macro summary from food nutrients
        let macroSummary = extractMacroSummary()

        return FDCFoodSummary(
            id: fdcId,
            name: description.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.isEmpty ? nil : brand,
            serving: serving,
            upc: gtinUpc,
            publishedDate: publishedDate,
            modifiedDate: modifiedDate,
            dataType: dataType,
            brandOwner: brandOwner,
            brandName: brandName,
            servingSize: servingSize,
            servingSizeUnit: servingSizeUnit,
            householdServingFullText: householdServingFullText,
            packageWeight: packageWeight,
            foodCategory: foodCategory,
            foodCategoryId: nil, // Not available in search response
            ingredients: ingredients,
            marketCountry: marketCountry,
            tradeChannels: tradeChannels,
            calories: labelNutrients.calories,
            protein: labelNutrients.protein,
            fat: labelNutrients.fat,
            saturatedFat: labelNutrients.saturatedFat,
            transFat: labelNutrients.transFat,
            cholesterol: labelNutrients.cholesterol,
            sodium: labelNutrients.sodium,
            carbohydrates: labelNutrients.carbohydrates,
            fiber: labelNutrients.fiber,
            sugars: labelNutrients.sugars,
            calcium: labelNutrients.calcium,
            iron: labelNutrients.iron,
            potassium: labelNutrients.potassium,
            macroSummary: macroSummary,
        )
    }

    private struct LabelNutrientsData {
        let calories: Double?
        let protein: Double?
        let fat: Double?
        let saturatedFat: Double?
        let transFat: Double?
        let cholesterol: Double?
        let sodium: Double?
        let carbohydrates: Double?
        let fiber: Double?
        let sugars: Double?
        let calcium: Double?
        let iron: Double?
        let potassium: Double?
    }

    private func extractLabelNutrients() -> LabelNutrientsData {
        // For search results, we don't have label nutrients, so return nil values
        // This would be populated from the detail response
        LabelNutrientsData(
            calories: nil,
            protein: nil,
            fat: nil,
            saturatedFat: nil,
            transFat: nil,
            cholesterol: nil,
            sodium: nil,
            carbohydrates: nil,
            fiber: nil,
            sugars: nil,
            calcium: nil,
            iron: nil,
            potassium: nil,
        )
    }

    private func extractMacroSummary() -> MacroSummary? {
        guard let nutrients = foodNutrients else { return nil }

        var calories: Double = 0
        var protein: Double = 0
        var fat: Double = 0
        var carbohydrates: Double = 0
        var fiber: Double?
        var sugars: Double?

        for nutrient in nutrients {
            guard let nutrientId = nutrient.nutrient?.id,
                  let amount = nutrient.amount else { continue }

            switch nutrientId {
            case 1008: // Energy (kcal)
                calories = amount
            case 1003: // Protein
                protein = amount
            case 1004: // Total lipid (fat)
                fat = amount
            case 1005: // Carbohydrate, by difference
                carbohydrates = amount
            case 1079: // Fiber
                fiber = amount
            case 2000: // Sugars
                sugars = amount
            default:
                break
            }
        }

        return MacroSummary(
            calories: calories,
            protein: protein,
            fat: fat,
            carbohydrates: carbohydrates,
            fiber: fiber,
            sugars: sugars,
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
            carbs: Int(nutrientValues.carbs),
            dataType: nil,
            brandOwner: nil,
            brandName: nil,
            servingSize: nil,
            servingSizeUnit: nil,
            householdServingFullText: nil,
            packageWeight: nil,
            foodCategory: nil,
            foodCategoryId: nil,
            ingredients: nil,
            marketCountry: nil,
            tradeChannels: nil,
            publishedDate: nil,
            modifiedDate: nil,
            gtinUpc: nil,
            labelNutrients: nil,
            foodNutrients: nil,
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

        // Convert label nutrients to public model
        let convertedLabelNutrients = convertLabelNutrients(labelNutrients)

        // Convert food nutrients to public model
        let convertedFoodNutrients = convertFoodNutrients(foodNutrients)

        return FDCFoodDetails(
            id: fdcId,
            name: description.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.isEmpty ? nil : brand,
            calories: Int(nutrientValues.calories),
            protein: Int(nutrientValues.protein),
            fat: Int(nutrientValues.fat),
            carbs: Int(nutrientValues.carbs),
            dataType: dataType,
            brandOwner: brandOwner,
            brandName: brandName,
            servingSize: servingSize,
            servingSizeUnit: servingSizeUnit,
            householdServingFullText: householdServingFullText,
            packageWeight: packageWeight,
            foodCategory: foodCategory?.description,
            foodCategoryId: foodCategory?.id,
            ingredients: ingredients,
            marketCountry: marketCountry,
            tradeChannels: tradeChannels,
            publishedDate: publicationDate,
            modifiedDate: modifiedDate,
            gtinUpc: gtinUpc,
            labelNutrients: convertedLabelNutrients,
            foodNutrients: convertedFoodNutrients,
        )
    }

    private func convertLabelNutrients(_ labelNutrients: ProxyLabelNutrients?) -> LabelNutrients? {
        guard let labelNutrients else { return nil }

        return LabelNutrients(
            calories: labelNutrients.calories.map { NutrientValue(value: $0.value ?? 0, unit: nil) },
            fat: labelNutrients.fat.map { NutrientValue(value: $0.value ?? 0, unit: nil) },
            saturatedFat: labelNutrients.saturatedFat.map { NutrientValue(value: $0.value ?? 0, unit: nil) },
            transFat: labelNutrients.transFat.map { NutrientValue(value: $0.value ?? 0, unit: nil) },
            cholesterol: labelNutrients.cholesterol.map { NutrientValue(value: $0.value ?? 0, unit: nil) },
            sodium: labelNutrients.sodium.map { NutrientValue(value: $0.value ?? 0, unit: nil) },
            carbohydrates: labelNutrients.carbohydrates.map { NutrientValue(value: $0.value ?? 0, unit: nil) },
            fiber: labelNutrients.fiber.map { NutrientValue(value: $0.value ?? 0, unit: nil) },
            sugars: labelNutrients.sugars.map { NutrientValue(value: $0.value ?? 0, unit: nil) },
            protein: labelNutrients.protein.map { NutrientValue(value: $0.value ?? 0, unit: nil) },
            calcium: labelNutrients.calcium.map { NutrientValue(value: $0.value ?? 0, unit: nil) },
            iron: labelNutrients.iron.map { NutrientValue(value: $0.value ?? 0, unit: nil) },
            potassium: nil,
        )
    }

    private func convertFoodNutrients(_ foodNutrients: [ProxyFoodNutrient]?) -> [FoodNutrient]? {
        guard let foodNutrients else { return nil }

        return foodNutrients.compactMap { proxyNutrient in
            guard let nutrient = proxyNutrient.nutrient else { return nil }

            return FoodNutrient(
                id: nutrient.id,
                name: nutrient.name ?? "Unknown",
                unit: nutrient.unitName ?? "",
                amount: proxyNutrient.amount,
                basis: .perServing, // Default to per serving for now
            )
        }
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
            modifiedDate: nil,
            dataType: nil,
            brandOwner: brandOwner,
            brandName: brandOwner,
            servingSize: nil,
            servingSizeUnit: nil,
            householdServingFullText: nil,
            packageWeight: nil,
            foodCategory: nil,
            foodCategoryId: nil,
            ingredients: nil,
            marketCountry: nil,
            tradeChannels: nil,
            calories: nil,
            protein: nil,
            fat: nil,
            saturatedFat: nil,
            transFat: nil,
            cholesterol: nil,
            sodium: nil,
            carbohydrates: nil,
            fiber: nil,
            sugars: nil,
            calcium: nil,
            iron: nil,
            potassium: nil,
            macroSummary: nil,
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
            carbs: Int(carbs),
            dataType: nil,
            brandOwner: brandOwner,
            brandName: brandOwner,
            servingSize: nil,
            servingSizeUnit: nil,
            householdServingFullText: nil,
            packageWeight: nil,
            foodCategory: nil,
            foodCategoryId: nil,
            ingredients: nil,
            marketCountry: nil,
            tradeChannels: nil,
            publishedDate: nil,
            modifiedDate: nil,
            gtinUpc: nil,
            labelNutrients: nil,
            foodNutrients: nil,
        )
    }
}
