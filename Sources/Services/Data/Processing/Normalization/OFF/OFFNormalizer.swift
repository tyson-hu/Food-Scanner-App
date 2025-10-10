//
//  OFFNormalizer.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - OFF Normalizer

public struct OFFNormalizer {
    public init() {}

    public func normalize(_ envelope: OffEnvelope) -> NormalizedFood {
        normalizeOFFData(envelope, envelope.raw)
    }

    // MARK: - OFF Normalization

    private func normalizeOFFData(_ envelope: OffEnvelope, _ data: OffProduct) -> NormalizedFood {
        // Extract basic info
        let primaryName = data.productName ?? "Unknown Product"
        let brand = data.brands
        let barcodes = data.code.map { [$0] } ?? []

        // Determine food kind (OFF is typically branded)
        let kind: FoodKind = .branded

        // Extract serving information
        let serving = extractOFFServing(data)

        // Extract portions
        let portions = extractOFFPortions(data)

        // Determine base unit
        let baseUnit = determineBaseUnit(from: data.servingSize, category: data.categories)

        // Normalize nutrients
        let nutrients = normalizeOFFNutrients(data)

        // Create per100Base nutrients (canonical normalization)
        let per100Base = createPer100BaseNutrients(from: nutrients, baseUnit: baseUnit)

        // Calculate density if possible
        let densityGPerMl = calculateDensity(from: portions)

        // Extract image URL
        let imageUrl = data.imageURL?.absoluteString ?? data.imageSmallURL?.absoluteString

        // Extract ingredients
        let ingredientsText = data.ingredientsText

        // Determine completeness flags
        let completeness = determineCompleteness(
            hasNutrients: !nutrients.isEmpty,
            hasServing: serving != nil,
            hasPortions: !portions.isEmpty,
            hasIngredients: ingredientsText != nil,
            hasImage: imageUrl != nil
        )

        // Create field sources
        let fieldSources = FieldSources(
            primaryName: .off,
            brand: .off,
            barcodes: .off,
            imageUrl: .off,
            nutrients: .off,
            serving: .off,
            portions: .off,
            ingredients: .off
        )

        let foodSource: FoodSource = envelope.source == .fdc ? .fdc : .off
        return NormalizedFood(
            gid: envelope.gid ?? "unknown",
            source: foodSource,
            kind: kind,
            barcode: envelope.barcode,
            fetchedAt: envelope.fetchedAt,
            primaryName: primaryName,
            brand: brand,
            barcodes: barcodes,
            imageUrl: imageUrl,
            categoryIds: [],
            baseUnit: baseUnit,
            per100Base: per100Base,
            densityGPerMl: densityGPerMl,
            serving: serving,
            portions: portions,
            nutrients: nutrients,
            ingredientsText: ingredientsText,
            completeness: completeness,
            fieldSources: fieldSources,
            userOverrides: UserOverrides()
        )
    }

    private func extractOFFServing(_ data: OffProduct) -> NormalizedServing? {
        guard let servingSize = data.servingSize else {
            return nil
        }

        // Parse serving size string like "2 tbsp (32 g)"
        let grams = parseServingSizeToGrams(servingSize)

        return NormalizedServing(
            amount: data.servingQuantity,
            unit: "serving",
            household: servingSize,
            grams: grams,
            source: .off,
            estimateQuality: grams != nil ? .inferred : .guessed
        )
    }

    private func extractOFFPortions(_ data: OffProduct) -> [NormalizedPortion] {
        var portions: [NormalizedPortion] = []

        // Add default 100g portion
        portions.append(NormalizedPortion(
            label: "100 g",
            grams: 100,
            massG: 100,
            volMl: nil,
            source: .off,
            estimateQuality: .exact
        ))

        // Add serving portion if available
        if let servingSize = data.servingSize {
            let grams = parseServingSizeToGrams(servingSize)
            let milliliters = parseServingSizeToMl(servingSize)
            portions.append(NormalizedPortion(
                label: "1 serving",
                grams: grams,
                massG: grams,
                volMl: milliliters,
                source: .off,
                estimateQuality: grams != nil ? .inferred : .guessed
            ))
        }

        return portions
    }

    private func normalizeOFFNutrients(_ data: OffProduct) -> [NormalizedNutrient] {
        guard let nutriments = data.nutriments else {
            return []
        }

        var nutrients: [NormalizedNutrient] = []

        // Always normalize to per-100g canonical base
        // Prefer per-100g data, fallback to per-serving if needed

        // Add energy nutrients
        nutrients.append(contentsOf: normalizeOFFEnergy(nutriments, data))

        // Add macronutrients
        nutrients.append(contentsOf: normalizeOFFMacronutrients(nutriments, data))

        // Add other nutrients
        nutrients.append(contentsOf: normalizeOFFOtherNutrients(nutriments, data))

        return nutrients
    }

    private func normalizeOFFOtherNutrients(_ nutriments: OffNutriments, _ data: OffProduct) -> [NormalizedNutrient] {
        var nutrients: [NormalizedNutrient] = []

        // Break down logic into smaller helpers to reduce cyclomatic complexity
        appendSaturatedFat(from: nutriments, data, into: &nutrients)
        appendFiber(from: nutriments, data, into: &nutrients)
        appendSugars(from: nutriments, data, into: &nutrients)
        appendSodiumOrSalt(from: nutriments, data, into: &nutrients)
        appendMicronutrients(from: nutriments, into: &nutrients)

        return nutrients
    }

    private func appendSaturatedFat(
        from nutriments: OffNutriments,
        _ data: OffProduct,
        into nutrients: inout [NormalizedNutrient]
    ) {
        if let saturatedFat = nutriments.saturatedFat100g {
            nutrients.append(NormalizedNutrient(
                id: 1_258,
                name: "Fatty acids, total saturated",
                unit: "g",
                amount: saturatedFat,
                basis: .per100g,
                source: .off
            ))
        } else if let saturatedFatServing = nutriments.saturatedFatServing {
            let servingGrams = extractOFFServingGrams(data)
            let saturatedFatPer100g = servingGrams > 0 ? saturatedFatServing * (100.0 / servingGrams) :
                saturatedFatServing
            nutrients.append(NormalizedNutrient(
                id: 1_258,
                name: "Fatty acids, total saturated",
                unit: "g",
                amount: saturatedFatPer100g,
                basis: .per100g,
                source: .off
            ))
        }
    }

    private func appendFiber(
        from nutriments: OffNutriments,
        _ data: OffProduct,
        into nutrients: inout [NormalizedNutrient]
    ) {
        if let fiber = nutriments.fiber100g {
            nutrients.append(NormalizedNutrient(
                id: 1_079,
                name: "Fiber, total dietary",
                unit: "g",
                amount: fiber,
                basis: .per100g,
                source: .off
            ))
        } else if let fiberServing = nutriments.fiberServing {
            let servingGrams = extractOFFServingGrams(data)
            let fiberPer100g = servingGrams > 0 ? fiberServing * (100.0 / servingGrams) : fiberServing
            nutrients.append(NormalizedNutrient(
                id: 1_079,
                name: "Fiber, total dietary",
                unit: "g",
                amount: fiberPer100g,
                basis: .per100g,
                source: .off
            ))
        }
    }

    private func appendSugars(
        from nutriments: OffNutriments,
        _ data: OffProduct,
        into nutrients: inout [NormalizedNutrient]
    ) {
        if let sugars = nutriments.sugars100g {
            nutrients.append(NormalizedNutrient(
                id: 2_000,
                name: "Sugars, total including NLEA",
                unit: "g",
                amount: sugars,
                basis: .per100g,
                source: .off
            ))
        } else if let sugarsServing = nutriments.sugarsServing {
            let servingGrams = extractOFFServingGrams(data)
            let sugarsPer100g = servingGrams > 0 ? sugarsServing * (100.0 / servingGrams) : sugarsServing
            nutrients.append(NormalizedNutrient(
                id: 2_000,
                name: "Sugars, total including NLEA",
                unit: "g",
                amount: sugarsPer100g,
                basis: .per100g,
                source: .off
            ))
        }
    }

    private func appendSodiumOrSalt(
        from nutriments: OffNutriments,
        _ data: OffProduct,
        into nutrients: inout [NormalizedNutrient]
    ) {
        if let sodium = nutriments.sodium100g {
            nutrients.append(NormalizedNutrient(
                id: 1_093,
                name: "Sodium, Na",
                unit: "mg",
                amount: sodium * 1_000, // Convert g to mg
                basis: .per100g,
                source: .off
            ))
        } else if let sodiumServing = nutriments.sodiumServing {
            let servingGrams = extractOFFServingGrams(data)
            let sodiumPer100g = servingGrams > 0 ? sodiumServing * (100.0 / servingGrams) : sodiumServing
            nutrients.append(NormalizedNutrient(
                id: 1_093,
                name: "Sodium, Na",
                unit: "mg",
                amount: sodiumPer100g * 1_000, // Convert g to mg
                basis: .per100g,
                source: .off
            ))
        } else if let salt = nutriments.salt100g {
            // Convert salt to sodium (salt * 0.393)
            nutrients.append(NormalizedNutrient(
                id: 1_093,
                name: "Sodium, Na",
                unit: "mg",
                amount: salt * 0.393 * 1_000, // Convert g to mg
                basis: .per100g,
                source: .off
            ))
        } else if let saltServing = nutriments.saltServing {
            let servingGrams = extractOFFServingGrams(data)
            let saltPer100g = servingGrams > 0 ? saltServing * (100.0 / servingGrams) : saltServing
            nutrients.append(NormalizedNutrient(
                id: 1_093,
                name: "Sodium, Na",
                unit: "mg",
                amount: saltPer100g * 0.393 * 1_000, // Convert g to mg
                basis: .per100g,
                source: .off
            ))
        }
    }

    private func appendMicronutrients(from nutriments: OffNutriments, into nutrients: inout [NormalizedNutrient]) {
        if let calcium = nutriments.calcium100g {
            nutrients.append(NormalizedNutrient(
                id: 1_087,
                name: "Calcium, Ca",
                unit: "mg",
                amount: calcium * 1_000, // Convert g to mg
                basis: .per100g,
                source: .off
            ))
        }

        if let iron = nutriments.iron100g {
            nutrients.append(NormalizedNutrient(
                id: 1_089,
                name: "Iron, Fe",
                unit: "mg",
                amount: iron * 1_000, // Convert g to mg
                basis: .per100g,
                source: .off
            ))
        }

        if let potassium = nutriments.potassium100g {
            nutrients.append(NormalizedNutrient(
                id: 1_092,
                name: "Potassium, K",
                unit: "mg",
                amount: potassium * 1_000, // Convert g to mg
                basis: .per100g,
                source: .off
            ))
        }
    }

    // MARK: - OFF Nutrient Helper Functions

    private func normalizeOFFEnergy(_ nutriments: OffNutriments, _ data: OffProduct) -> [NormalizedNutrient] {
        var nutrients: [NormalizedNutrient] = []

        if let calories = nutriments.energyKcal100g {
            nutrients.append(NormalizedNutrient(
                id: 1_008,
                name: "Energy",
                unit: "kcal",
                amount: calories,
                basis: .per100g,
                source: .off
            ))
        } else if let caloriesServing = nutriments.energyKcalServing {
            // Convert per-serving to per-100g
            let servingGrams = extractOFFServingGrams(data)
            let caloriesPer100g = servingGrams > 0 ? caloriesServing * (100.0 / servingGrams) : caloriesServing
            nutrients.append(NormalizedNutrient(
                id: 1_008,
                name: "Energy",
                unit: "kcal",
                amount: caloriesPer100g,
                basis: .per100g,
                source: .off
            ))
        } else if let energyKj = nutriments.energyKj100g {
            // Convert kJ to kcal (kJ * 0.239)
            nutrients.append(NormalizedNutrient(
                id: 1_008,
                name: "Energy",
                unit: "kcal",
                amount: energyKj * 0.239,
                basis: .per100g,
                source: .off
            ))
        } else if let energyKjServing = nutriments.energyKjServing {
            // Convert per-serving kJ to per-100g kcal
            let servingGrams = extractOFFServingGrams(data)
            let energyKjPer100g = servingGrams > 0 ? energyKjServing * (100.0 / servingGrams) : energyKjServing
            nutrients.append(NormalizedNutrient(
                id: 1_008,
                name: "Energy",
                unit: "kcal",
                amount: energyKjPer100g * 0.239,
                basis: .per100g,
                source: .off
            ))
        }

        return nutrients
    }

    private func normalizeOFFMacronutrients(_ nutriments: OffNutriments, _ data: OffProduct) -> [NormalizedNutrient] {
        var nutrients: [NormalizedNutrient] = []

        // Protein
        if let protein = nutriments.proteins100g {
            nutrients.append(NormalizedNutrient(
                id: 1_003,
                name: "Protein",
                unit: "g",
                amount: protein,
                basis: .per100g,
                source: .off
            ))
        } else if let proteinServing = nutriments.proteinsServing {
            let servingGrams = extractOFFServingGrams(data)
            let proteinPer100g = servingGrams > 0 ? proteinServing * (100.0 / servingGrams) : proteinServing
            nutrients.append(NormalizedNutrient(
                id: 1_003,
                name: "Protein",
                unit: "g",
                amount: proteinPer100g,
                basis: .per100g,
                source: .off
            ))
        }

        // Carbohydrates
        if let carbs = nutriments.carbs100g {
            nutrients.append(NormalizedNutrient(
                id: 1_005,
                name: "Carbohydrate, by difference",
                unit: "g",
                amount: carbs,
                basis: .per100g,
                source: .off
            ))
        } else if let carbsServing = nutriments.carbohydratesServing {
            let servingGrams = extractOFFServingGrams(data)
            let carbsPer100g = servingGrams > 0 ? carbsServing * (100.0 / servingGrams) : carbsServing
            nutrients.append(NormalizedNutrient(
                id: 1_005,
                name: "Carbohydrate, by difference",
                unit: "g",
                amount: carbsPer100g,
                basis: .per100g,
                source: .off
            ))
        }

        // Fat
        if let fat = nutriments.fat100g {
            nutrients.append(NormalizedNutrient(
                id: 1_004,
                name: "Total lipid (fat)",
                unit: "g",
                amount: fat,
                basis: .per100g,
                source: .off
            ))
        } else if let fatServing = nutriments.fatServing {
            let servingGrams = extractOFFServingGrams(data)
            let fatPer100g = servingGrams > 0 ? fatServing * (100.0 / servingGrams) : fatServing
            nutrients.append(NormalizedNutrient(
                id: 1_004,
                name: "Total lipid (fat)",
                unit: "g",
                amount: fatPer100g,
                basis: .per100g,
                source: .off
            ))
        }

        return nutrients
    }

    // MARK: - Helper Functions

    private func extractOFFServingGrams(_ data: OffProduct) -> Double {
        guard let servingSize = data.servingSize else {
            return 0
        }
        return parseServingSizeToGrams(servingSize) ?? 0
    }

    private func determineCompleteness(
        hasNutrients: Bool,
        hasServing: Bool,
        hasPortions: Bool,
        hasIngredients: Bool,
        hasImage: Bool
    ) -> CompletenessFlags {
        CompletenessFlags(
            core: hasNutrients && hasServing,
            label: hasNutrients && hasServing, // Label nutrients require both nutrients and serving info
            micros: hasNutrients, // Micronutrients are part of general nutrition data
            portions: hasPortions,
            ingredients: hasIngredients,
            image: hasImage
        )
    }

    private func parseServingSizeToGrams(_ servingSize: String) -> Double? {
        // Parse strings like "2 tbsp (32 g)" or "1 cup (240ml)"
        let pattern = #"\((\d+(?:\.\d+)?)\s*g\)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(servingSize.startIndex..., in: servingSize)

        if let match = regex?.firstMatch(in: servingSize, options: [], range: range),
           let gramsRange = Range(match.range(at: 1), in: servingSize) {
            return Double(String(servingSize[gramsRange]))
        }

        return nil
    }

    private func parseServingSizeToMl(_ servingSize: String) -> Double? {
        // Parse strings like "2 tbsp (30 ml)" or "1 cup (240ml)"
        let pattern = #"\((\d+(?:\.\d+)?)\s*ml\)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(servingSize.startIndex..., in: servingSize)

        if let match = regex?.firstMatch(in: servingSize, options: [], range: range),
           let mlRange = Range(match.range(at: 1), in: servingSize) {
            return Double(String(servingSize[mlRange]))
        }

        return nil
    }

    /// Determine base unit from serving size unit and category
    private func determineBaseUnit(from servingSize: String?, category: String?) -> BaseUnit {
        // Check serving size unit first
        if let servingSize = servingSize?.lowercased() {
            // Volume units → ml
            if [
                "ml",
                "milliliter",
                "milliliters",
                "mlt",
                "l",
                "liter",
                "liters",
                "fl oz",
                "fluid ounce",
                "fluid ounces"
            ].contains(where: { servingSize.contains($0) }) {
                return .milliliters
            }
        }

        // Check category for beverages
        if let category = category?.lowercased() {
            if category.contains("beverage") || category.contains("drink") || category.contains("juice") || category
                .contains("soda") {
                return .milliliters
            }
        }

        // Default to grams
        return .grams
    }

    /// Create per100Base nutrients from existing nutrients
    private func createPer100BaseNutrients(
        from nutrients: [NormalizedNutrient],
        baseUnit: BaseUnit
    ) -> [NormalizedNutrient] {
        nutrients.map { nutrient in
            // Convert per100g nutrients to per100Base
            if nutrient.basis == .per100g {
                return NormalizedNutrient(
                    id: nutrient.id,
                    name: nutrient.name,
                    unit: nutrient.unit,
                    amount: nutrient.amount,
                    basis: .per100Base,
                    source: nutrient.source
                )
            }
            return nutrient
        }
    }

    /// Calculate density from portions if both mass and volume are available
    private func calculateDensity(from portions: [NormalizedPortion]) -> Double? {
        for portion in portions {
            if let massG = portion.massG, let volMl = portion.volMl, volMl > 0 {
                return massG / volMl
            }
        }
        return nil
    }
}
