//
//  FDCModelConverter.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - FDC Model Converter

public struct FDCModelConverter {
    private let nutrientParser = FDCNutrientParser()

    public init() {}

    public func convertToFDCFoodDetails(_ proxyResponse: ProxyFoodDetailResponse) -> FDCFoodDetails {
        let nutrientValues = nutrientParser.parseNutrients(from: proxyResponse)
        let brand = proxyResponse.brandOwner ?? proxyResponse.brandName ?? ""

        // Convert label nutrients to public model
        let convertedLabelNutrients = convertLabelNutrients(proxyResponse.labelNutrients)

        // Convert food nutrients to public model
        let convertedFoodNutrients = convertFoodNutrients(proxyResponse.foodNutrients)

        return FDCFoodDetails(
            id: proxyResponse.fdcId,
            name: proxyResponse.description.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.isEmpty ? nil : brand,
            calories: Int(nutrientValues.calories),
            protein: Int(nutrientValues.protein),
            fat: Int(nutrientValues.fat),
            carbs: Int(nutrientValues.carbs),
            dataType: proxyResponse.dataType,
            brandOwner: proxyResponse.brandOwner,
            brandName: proxyResponse.brandName,
            servingSize: proxyResponse.servingSize,
            servingSizeUnit: proxyResponse.servingSizeUnit,
            householdServingFullText: proxyResponse.householdServingFullText,
            packageWeight: proxyResponse.packageWeight,
            foodCategory: proxyResponse.foodCategory?.description,
            foodCategoryId: proxyResponse.foodCategory?.id,
            ingredients: proxyResponse.ingredients,
            marketCountry: proxyResponse.marketCountry,
            tradeChannels: proxyResponse.tradeChannels,
            publishedDate: proxyResponse.publicationDate,
            modifiedDate: proxyResponse.modifiedDate,
            gtinUpc: proxyResponse.gtinUpc,
            labelNutrients: convertedLabelNutrients,
            foodNutrients: convertedFoodNutrients
        )
    }

    private func convertLabelNutrients(_ labelNutrients: ProxyLabelNutrients?) -> LabelNutrients? {
        guard let labelNutrients else { return nil }

        return LabelNutrients(
            calories: labelNutrients.calories.map { NutrientValue(value: $0.value, unit: nil) },
            fat: labelNutrients.fat.map { NutrientValue(value: $0.value, unit: nil) },
            saturatedFat: labelNutrients.saturatedFat.map { NutrientValue(value: $0.value, unit: nil) },
            transFat: labelNutrients.transFat.map { NutrientValue(value: $0.value, unit: nil) },
            cholesterol: labelNutrients.cholesterol.map { NutrientValue(value: $0.value, unit: nil) },
            sodium: labelNutrients.sodium.map { NutrientValue(value: $0.value, unit: nil) },
            carbohydrates: labelNutrients.carbohydrates.map { NutrientValue(value: $0.value, unit: nil) },
            fiber: labelNutrients.fiber.map { NutrientValue(value: $0.value, unit: nil) },
            sugars: labelNutrients.sugars.map { NutrientValue(value: $0.value, unit: nil) },
            protein: labelNutrients.protein.map { NutrientValue(value: $0.value, unit: nil) },
            calcium: labelNutrients.calcium.map { NutrientValue(value: $0.value, unit: nil) },
            iron: labelNutrients.iron.map { NutrientValue(value: $0.value, unit: nil) },
            potassium: nil
        )
    }

    private func convertFoodNutrients(_ foodNutrients: [ProxyFoodNutrient]?) -> [FoodNutrient]? {
        guard let foodNutrients else { return nil }

        return foodNutrients.compactMap { proxyNutrient -> FoodNutrient? in
            guard let nutrient = proxyNutrient.nutrient else { return nil }

            return FoodNutrient(
                id: nutrient.id,
                name: nutrient.name,
                unit: nutrient.unitName ?? "",
                amount: proxyNutrient.amount,
                basis: .perServing // Default to per serving for now
            )
        }
    }
}
