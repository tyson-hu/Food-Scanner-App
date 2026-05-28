//
//  FDCNormalizer.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - FDC Normalizer

public struct FDCNormalizer {
    public init() {}

    public func normalize(_ envelope: FdcEnvelope) -> NormalizedFood {
        normalizeFDCData(envelope, envelope.raw)
    }

    // MARK: - FDC Normalization

    private func normalizeFDCData(_ envelope: FdcEnvelope, _ data: FdcProduct) -> NormalizedFood {
        // Extract basic info
        let primaryName = data.description ?? "Unknown Food"
        let brand = data.brandName ?? data.brandOwner
        let barcodes = data.gtinUpc.map { [$0] } ?? []

        // Determine food kind
        let kind: FoodKind = switch data.dataType {
        case .branded:
            .branded
        case .foundation, .srLegacy:
            .generic
        default:
            .generic
        }

        // Extract serving information
        let serving = extractFDCServing(data)

        // Extract portions
        let portions = extractFDCPortions(data)

        // Determine base unit
        let baseUnit = determineBaseUnit(from: data.servingSizeUnit, category: data.brandedFoodCategory)

        // Normalize nutrients
        let nutrients = normalizeFDCNutrients(data)

        // Create per100Base nutrients (canonical normalization)
        let per100Base = createPer100BaseNutrients(from: nutrients, baseUnit: baseUnit)

        // Calculate density if possible
        let densityGPerMl = calculateDensity(from: portions)

        // Extract image URL (FDC doesn't typically have images)
        let imageUrl: String? = nil

        // Extract ingredients
        let ingredientsText = data.ingredients

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
            primaryName: .fdc,
            brand: .fdc,
            barcodes: .fdc,
            imageUrl: .fdc,
            nutrients: .fdc,
            serving: .fdc,
            portions: .fdc,
            ingredients: .fdc
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

    private func extractFDCServing(_ data: FdcProduct) -> NormalizedServing? {
        guard let servingSize = data.servingSize,
              let servingSizeUnit = data.servingSizeUnit else {
            return nil
        }

        let grams = convertToGrams(amount: servingSize, unit: servingSizeUnit)

        return NormalizedServing(
            amount: servingSize,
            unit: servingSizeUnit,
            household: data.householdServingFullText,
            grams: grams,
            source: .fdc,
            estimateQuality: grams != nil ? .exact : .inferred
        )
    }

    private func extractFDCPortions(_ data: FdcProduct) -> [NormalizedPortion] {
        var portions: [NormalizedPortion] = []

        // Add serving portion if available
        if let servingSize = data.servingSize, let servingSizeUnit = data.servingSizeUnit {
            let grams = convertToGrams(amount: servingSize, unit: servingSizeUnit)
            let milliliters = convertToMl(amount: servingSize, unit: servingSizeUnit)
            portions.append(NormalizedPortion(
                label: data.householdServingFullText ?? "1 serving",
                grams: grams,
                massG: grams,
                volMl: milliliters,
                source: .fdc,
                estimateQuality: grams != nil ? .exact : .inferred
            ))
        }

        // Always add 100g portion
        portions.append(NormalizedPortion(
            label: "100 g",
            grams: 100,
            massG: 100,
            volMl: nil,
            source: .fdc,
            estimateQuality: .exact
        ))

        // Add portions from foodPortions
        if let foodPortions = data.foodPortions {
            for measure in foodPortions {
                guard let amount = measure.amount,
                      let unit = measure.measureUnit?.name,
                      let description = measure.portionDescription else {
                    continue
                }

                let grams = convertToGrams(amount: amount, unit: unit)

                portions.append(NormalizedPortion(
                    label: description,
                    grams: grams,
                    massG: grams,
                    volMl: convertToMl(amount: amount, unit: unit),
                    source: .fdc,
                    estimateQuality: grams != nil ? .exact : .inferred
                ))
            }
        }

        return portions
    }

    private func normalizeFDCNutrients(_ data: FdcProduct) -> [NormalizedNutrient] {
        var nutrients: [NormalizedNutrient] = []

        // Extract label nutrients (per-serving) and convert to per-100g
        if let labelNutrients = data.labelNutrients {
            let servingGrams = extractServingGrams(data)
            nutrients.append(contentsOf: extractLabelNutrients(labelNutrients, servingGrams: servingGrams))
        }

        // Add food nutrients (already per-100g)
        if let foodNutrients = data.foodNutrients {
            for nutrient in foodNutrients {
                guard let amount = nutrient.amount,
                      let nutrientInfo = nutrient.nutrient else {
                    continue
                }

                nutrients.append(NormalizedNutrient(
                    id: nutrientInfo.id,
                    name: nutrientInfo.name ?? "Unknown",
                    unit: nutrientInfo.unitName ?? "g",
                    amount: amount,
                    basis: .per100g,
                    source: .fdc
                ))
            }
        }

        return nutrients
    }

    private func extractLabelNutrients(
        _ labelNutrients: FdcLabelNutrients,
        servingGrams: Double?
    ) -> [NormalizedNutrient] {
        var nutrients: [NormalizedNutrient] = []

        struct NutrientMapping {
            let value: FdcLNValue?
            let name: String
            let id: Int?
        }

        let nutrientMappings: [NutrientMapping] = [
            NutrientMapping(value: labelNutrients.calories, name: "Energy", id: 1_008),
            NutrientMapping(value: labelNutrients.protein, name: "Protein", id: 1_003),
            NutrientMapping(value: labelNutrients.fat, name: "Total lipid (fat)", id: 1_004),
            NutrientMapping(value: labelNutrients.saturatedFat, name: "Fatty acids, total saturated", id: 1_258),
            NutrientMapping(value: labelNutrients.transFat, name: "Fatty acids, total trans", id: 1_257),
            NutrientMapping(value: labelNutrients.cholesterol, name: "Cholesterol", id: 1_253),
            NutrientMapping(value: labelNutrients.sodium, name: "Sodium, Na", id: 1_093),
            NutrientMapping(value: labelNutrients.carbohydrates, name: "Carbohydrate, by difference", id: 1_005),
            NutrientMapping(value: labelNutrients.fiber, name: "Fiber, total dietary", id: 1_079),
            NutrientMapping(value: labelNutrients.sugars, name: "Sugars, total including NLEA", id: 2_000),
            NutrientMapping(value: labelNutrients.calcium, name: "Calcium, Ca", id: 1_087),
            NutrientMapping(value: labelNutrients.iron, name: "Iron, Fe", id: 1_089),
            NutrientMapping(value: labelNutrients.potassium, name: "Potassium, K", id: 1_092)
        ]

        for mapping in nutrientMappings {
            guard let value = mapping.value?.value else { continue }

            // Convert per-serving to per-100g if we have serving size in grams
            let amount: Double
            let basis: NutrientBasis

            if let servingGrams, servingGrams > 0 {
                amount = value * (100.0 / servingGrams)
                basis = .per100g
            } else {
                amount = value
                basis = .perServing
            }

            nutrients.append(NormalizedNutrient(
                id: mapping.id,
                name: mapping.name,
                unit: "g", // FDC label nutrients don't specify units, default to grams
                amount: amount,
                basis: basis,
                source: .fdc
            ))
        }

        return nutrients
    }

    // MARK: - Helper Functions

    private func extractServingGrams(_ data: FdcProduct) -> Double? {
        guard let servingSize = data.servingSize,
              let servingSizeUnit = data.servingSizeUnit else {
            return nil
        }
        return convertToGrams(amount: servingSize, unit: servingSizeUnit)
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

    private func convertToGrams(amount: Double, unit: String) -> Double? {
        let unitLower = unit.lowercased()

        switch unitLower {
        case "g", "gram", "grams":
            return amount
        case "kg", "kilogram", "kilograms":
            return amount * 1_000
        case "oz", "ounce", "ounces":
            return amount * 28.3495
        case "lb", "pound", "pounds":
            return amount * 453.592
        case "ml", "milliliter", "milliliters", "mlt":
            return amount // Approximate for water
        case "l", "liter", "liters":
            return amount * 1_000 // Approximate for water
        case "cup", "cups":
            return amount * 240 // Approximate for water
        case "tbsp", "tablespoon", "tablespoons":
            return amount * 15 // Approximate for water
        case "tsp", "teaspoon", "teaspoons":
            return amount * 5 // Approximate for water
        default:
            return nil
        }
    }

    private func convertToMl(amount: Double, unit: String) -> Double? {
        let unitLower = unit.lowercased()

        switch unitLower {
        case "ml", "milliliter", "milliliters", "mlt":
            return amount
        case "l", "liter", "liters":
            return amount * 1_000
        case "fl oz", "fluid ounce", "fluid ounces":
            return amount * 29.5735
        case "cup", "cups":
            return amount * 240
        case "tbsp", "tablespoon", "tablespoons":
            return amount * 15
        case "tsp", "teaspoon", "teaspoons":
            return amount * 5
        case "g", "gram", "grams", "kg", "kilogram", "kilograms", "oz", "ounce", "ounces", "lb", "pound", "pounds":
            return amount // Approximate 1:1 for water
        default:
            return nil
        }
    }

    /// Determine base unit from serving size unit and category
    private func determineBaseUnit(from servingSizeUnit: String?, category: String?) -> BaseUnit {
        // Check serving size unit first
        if let unit = servingSizeUnit?.lowercased() {
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
            ].contains(unit) {
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
