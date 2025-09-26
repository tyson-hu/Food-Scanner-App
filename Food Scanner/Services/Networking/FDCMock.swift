//
//  FDCMock.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/17/25.
//  Updated: consolidated all mock data & logic
//

import Foundation

struct FDCMock: FDCClient {
    // Canonical mock catalog (details first; summaries derived from this)
    private static let catalog: [FDCFoodDetails] = [
        .init(id: 1234, name: "Greek Yogurt, Plain", brand: "Fage", calories: 100, protein: 17, fat: 0, carbs: 6),
        .init(id: 5678, name: "Peanut Butter", brand: "Jif", calories: 190, protein: 7, fat: 16, carbs: 8),
        .init(id: 9012, name: "Brown Rice, cooked", brand: nil, calories: 216, protein: 5, fat: 2, carbs: 45),
        // extras for nicer search feel
        .init(id: 1001, name: "Banana, raw", brand: nil, calories: 90, protein: 1, fat: 0, carbs: 23),
        .init(id: 1002, name: "Chicken Breast, cooked", brand: nil, calories: 165, protein: 31, fat: 3, carbs: 0),
        .init(id: 1003, name: "Oatmeal, rolled oats", brand: nil, calories: 150, protein: 5, fat: 3, carbs: 27),
        .init(
            id: 1004,
            name: "Greek Yogurt, Strawberry",
            brand: "Chobani",
            calories: 140,
            protein: 12,
            fat: 2,
            carbs: 16
        ),
    ]

    func searchFoods(matching query: String, page: Int) async throws -> [FDCFoodSummary] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        try? await Task.sleep(nanoseconds: 150_000_000) // small latency

        let tokens = trimmed.lowercased().split(separator: " ")
        let filtered = Self.catalog.filter { food in
            let hay = "\(food.name) \(food.brand ?? "")".lowercased()
            return tokens.allSatisfy { hay.contains($0) }
        }

        // naive paging: 20 per page
        let pageSize = 20
        let start = max(0, (page - 1) * pageSize)
        let end = min(filtered.count, start + pageSize)
        let slice = (start < end) ? filtered[start ..< end] : []

        return slice.map {
            FDCFoodSummary(
                id: $0.id,
                name: $0.name,
                brand: $0.brand,
                serving: nil,
                upc: nil,
                publishedDate: nil,
                modifiedDate: nil
            )
        }
    }

    func fetchFoodDetails(fdcId: Int) async throws -> FDCFoodDetails {
        try? await Task.sleep(nanoseconds: 120_000_000)
        if let hit = Self.catalog.first(where: { $0.id == fdcId }) {
            return hit
        }
        // safe fallback
        return .init(id: fdcId, name: "Brown Rice, cooked", brand: nil, calories: 216, protein: 5, fat: 2, carbs: 45)
    }

    func fetchFoodDetailResponse(fdcId: Int) async throws -> ProxyFoodDetailResponse {
        try? await Task.sleep(nanoseconds: 120_000_000)

        // Create a mock ProxyFoodDetailResponse with realistic data
        let mockNutrients = [
            ProxyFoodNutrient(
                nutrient: ProxyNutrient(id: 1008, number: "208", name: "Energy", rank: 300, unitName: "kcal"),
                amount: 100.0,
                type: "FoodNutrient",
                foodNutrientDerivation: ProxyFoodNutrientDerivation(
                    id: 1,
                    code: "LCCD",
                    description: "Calculated from a daily value percentage per serving size measure",
                    foodNutrientSource: ProxyFoodNutrientSource(
                        id: 1,
                        code: "LCCD",
                        description: "Calculated from a daily value percentage per serving size measure"
                    )
                ),
                id: 1,
                dataPoints: 1,
                max: nil,
                min: nil,
                median: nil,
                minYearAcquired: nil,
                nutrientAnalysisDetails: nil
            ),
            ProxyFoodNutrient(
                nutrient: ProxyNutrient(id: 1003, number: "203", name: "Protein", rank: 600, unitName: "g"),
                amount: 7.0,
                type: "FoodNutrient",
                foodNutrientDerivation: nil,
                id: 2,
                dataPoints: 1,
                max: nil,
                min: nil,
                median: nil,
                minYearAcquired: nil,
                nutrientAnalysisDetails: nil
            ),
        ]

        if let hit = Self.catalog.first(where: { $0.id == fdcId }) {
            // Create label nutrients for testing fallback functionality
            let labelNutrients = ProxyLabelNutrients(
                fat: ProxyLabelNutrient(value: Double(hit.fat)),
                saturatedFat: nil,
                transFat: nil,
                cholesterol: nil,
                sodium: nil,
                carbohydrates: ProxyLabelNutrient(value: Double(hit.carbs)),
                fiber: nil,
                sugars: nil,
                protein: ProxyLabelNutrient(value: Double(hit.protein)),
                calcium: nil,
                iron: nil,
                calories: ProxyLabelNutrient(value: Double(hit.calories))
            )

            return ProxyFoodDetailResponse(
                fdcId: hit.id,
                description: hit.name,
                publicationDate: "2023-01-01",
                foodNutrients: mockNutrients,
                dataType: "Branded",
                foodClass: "Processed",
                inputFoods: nil,
                foodComponents: nil,
                foodAttributes: nil,
                nutrientConversionFactors: nil,
                ndbNumber: hit.id,
                isHistoricalReference: false,
                foodCategory: ProxyFoodCategory(id: 1, code: "0100", description: "Dairy and Egg Products"),
                brandOwner: hit.brand,
                brandName: hit.brand,
                dataSource: "Mock",
                gtinUpc: nil,
                marketCountry: "United States",
                servingSize: 100.0,
                servingSizeUnit: "g",
                householdServingFullText: "1 cup",
                ingredients: "Brown rice",
                brandedFoodCategory: "Grains",
                packageWeight: nil,
                discontinuedDate: nil,
                availableDate: "2023-01-01",
                modifiedDate: "2023-01-01",
                foodPortions: nil,
                foodUpdateLog: nil,
                labelNutrients: labelNutrients,
                scientificName: nil,
                footNote: nil,
                foodCode: nil,
                endDate: nil,
                startDate: nil,
                wweiaFoodCategory: nil,
                foodMeasures: nil,
                microbes: nil,
                tradeChannels: nil,
                allHighlightFields: nil,
                score: nil,
                foodVersionIds: nil,
                foodAttributeTypes: nil,
                finalFoodInputFoods: nil
            )
        }

        // safe fallback
        return ProxyFoodDetailResponse(
            fdcId: fdcId,
            description: "Brown Rice, cooked",
            publicationDate: "2023-01-01",
            foodNutrients: mockNutrients,
            dataType: "Foundation",
            foodClass: "Raw",
            inputFoods: nil,
            foodComponents: nil,
            foodAttributes: nil,
            nutrientConversionFactors: nil,
            ndbNumber: fdcId,
            isHistoricalReference: false,
            foodCategory: ProxyFoodCategory(id: 2, code: "2000", description: "Cereal Grains and Pasta"),
            brandOwner: nil,
            brandName: nil,
            dataSource: "Mock",
            gtinUpc: nil,
            marketCountry: "United States",
            servingSize: 100.0,
            servingSizeUnit: "g",
            householdServingFullText: "1 cup",
            ingredients: "Brown rice",
            brandedFoodCategory: "Grains",
            packageWeight: nil,
            discontinuedDate: nil,
            availableDate: "2023-01-01",
            modifiedDate: "2023-01-01",
            foodPortions: nil,
            foodUpdateLog: nil,
            labelNutrients: nil,
            scientificName: nil,
            footNote: nil,
            foodCode: nil,
            endDate: nil,
            startDate: nil,
            wweiaFoodCategory: nil,
            foodMeasures: nil,
            microbes: nil,
            tradeChannels: nil,
            allHighlightFields: nil,
            score: nil,
            foodVersionIds: nil,
            foodAttributeTypes: nil,
            finalFoodInputFoods: nil
        )
    }
}
