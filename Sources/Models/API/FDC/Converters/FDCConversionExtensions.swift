//
//  FDCConversionExtensions.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - Conversion Extensions

// Conversion extension for ProxyFoodDetailResponse
extension ProxyFoodDetailResponse {
    func toFDCFoodDetails() -> FDCFoodDetails {
        FDCModelConverter().convertToFDCFoodDetails(self)
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
            macroSummary: nil
        )
    }

    func toFDCFoodDetails() -> FDCFoodDetails {
        let calories = foodNutrients.first { $0.nutrient.id == 1_008 }?.amount ?? 0
        let protein = foodNutrients.first { $0.nutrient.id == 1_003 }?.amount ?? 0
        let fat = foodNutrients.first { $0.nutrient.id == 1_004 }?.amount ?? 0
        let carbs = foodNutrients.first { $0.nutrient.id == 1_005 }?.amount ?? 0

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
            foodNutrients: nil
        )
    }
}
