//
//  FoodNormalizationService.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - Food Normalization Service

public protocol FoodNormalizationService: Sendable {
    /// Normalize a food envelope to canonical models
    func normalize(_ envelope: Envelope<AnyCodable>) -> NormalizedFood

    /// Normalize FDC envelope to canonical models
    func normalizeFDC(_ envelope: FdcEnvelope) -> NormalizedFood

    /// Normalize OFF envelope to canonical models
    func normalizeOFF(_ envelope: OffEnvelope) -> NormalizedFood

    /// Merge FDC and OFF data with proper precedence rules
    func mergeFoodData(fdc: NormalizedFood?, off: NormalizedFood?) -> NormalizedFood?
}

public struct FoodNormalizationServiceImpl: FoodNormalizationService {
    private let fdcNormalizer = FDCNormalizer()
    private let offNormalizer = OFFNormalizer()

    public init() {}

    public func normalize(_ envelope: Envelope<AnyCodable>) -> NormalizedFood {
        // Try to decode as FDC first, then OFF based on source
        switch envelope.source {
        case .fdc:
            do {
                // Convert AnyCodable to FdcFood by decoding the raw data
                let rawData = try JSONEncoder().encode(envelope.raw)
                let fdcFood = try JSONDecoder().decode(FdcFood.self, from: rawData)
                let fdcEnvelope = FdcEnvelope(
                    gid: envelope.gid ?? "unknown",
                    source: envelope.source,
                    barcode: envelope.barcode,
                    fetchedAt: envelope.fetchedAt,
                    raw: fdcFood
                )
                return normalizeFDC(fdcEnvelope)
            } catch {
                return createEmptyNormalizedFood(envelope.gid ?? "unknown", envelope.source)
            }
        case .off:
            do {
                // Convert AnyCodable to OffProduct by decoding the raw data
                let rawData = try JSONEncoder().encode(envelope.raw)
                let offProduct = try JSONDecoder().decode(OffProduct.self, from: rawData)
                let offEnvelope = OffEnvelope(
                    gid: envelope.gid ?? "unknown",
                    source: envelope.source,
                    barcode: envelope.barcode,
                    fetchedAt: envelope.fetchedAt,
                    raw: offProduct
                )
                return normalizeOFF(offEnvelope)
            } catch {
                return createEmptyNormalizedFood(envelope.gid ?? "unknown", envelope.source)
            }
        }
    }

    public func normalizeFDC(_ envelope: FdcEnvelope) -> NormalizedFood {
        fdcNormalizer.normalize(envelope)
    }

    public func normalizeOFF(_ envelope: OffEnvelope) -> NormalizedFood {
        offNormalizer.normalize(envelope)
    }

    /// Merge FDC and OFF data with proper precedence rules
    public func mergeFoodData(fdc: NormalizedFood?, off: NormalizedFood?) -> NormalizedFood? {
        guard let fdc else { return off }
        guard let off else { return fdc }

        // Prefer FDC for nutrients/servings, OFF for image/ingredients/FOP
        let mergedNutrients = mergeNutrients(fdc: fdc.nutrients, off: off.nutrients)
        let mergedPortions = mergePortions(fdc: fdc.portions, off: off.portions)
        let mergedServing = fdc.serving ?? off.serving

        // Prefer OFF for image and ingredients
        let imageUrl = off.imageUrl ?? fdc.imageUrl
        let ingredientsText = off.ingredientsText ?? fdc.ingredientsText

        // Merge field sources to track which source provided each field
        let fieldSources = FieldSources(
            primaryName: fdc.fieldSources.primaryName, // FDC typically has better names
            brand: fdc.fieldSources.brand, // FDC typically has better brand info
            barcodes: fdc.fieldSources.barcodes, // FDC typically has better barcode info
            imageUrl: off.imageUrl != nil ? .off : fdc.fieldSources.imageUrl,
            nutrients: fdc.nutrients.isEmpty ? .off : .fdc, // Prefer FDC for nutrients
            serving: fdc.serving != nil ? .fdc : .off,
            portions: fdc.portions.isEmpty ? .off : .fdc, // Prefer FDC for portions
            ingredients: off.ingredientsText != nil ? .off : fdc.fieldSources.ingredients
        )

        // Determine completeness based on merged data
        let completeness = determineCompleteness(
            hasNutrients: !mergedNutrients.isEmpty,
            hasServing: mergedServing != nil,
            hasPortions: !mergedPortions.isEmpty,
            hasIngredients: ingredientsText != nil,
            hasImage: imageUrl != nil
        )

        return NormalizedFood(
            gid: fdc.gid, // Use FDC GID as primary
            source: fdc.source, // Use FDC as primary source
            kind: fdc.kind,
            barcode: fdc.barcode ?? off.barcode,
            fetchedAt: fdc.fetchedAt,
            primaryName: fdc.primaryName,
            brand: fdc.brand ?? off.brand,
            barcodes: fdc.barcodes.isEmpty ? off.barcodes : fdc.barcodes,
            imageUrl: imageUrl,
            categoryIds: fdc.categoryIds.isEmpty ? off.categoryIds : fdc.categoryIds,
            baseUnit: fdc.baseUnit, // Use FDC base unit as primary
            per100Base: mergedNutrients.map { nutrient in
                NormalizedNutrient(
                    id: nutrient.id,
                    name: nutrient.name,
                    unit: nutrient.unit,
                    amount: nutrient.amount,
                    basis: .per100Base,
                    source: nutrient.source
                )
            },
            densityGPerMl: fdc.densityGPerMl ?? off.densityGPerMl,
            serving: mergedServing,
            portions: mergedPortions,
            nutrients: mergedNutrients,
            ingredientsText: ingredientsText,
            completeness: completeness,
            fieldSources: fieldSources,
            userOverrides: fdc.userOverrides // Use FDC user overrides as primary
        )
    }

    // MARK: - Merging Helper Functions

    private func mergeNutrients(fdc: [NormalizedNutrient], off: [NormalizedNutrient]) -> [NormalizedNutrient] {
        var mergedNutrients: [NormalizedNutrient] = []
        var processedNutrientIds: Set<Int> = []

        // Prefer FDC nutrients (they're typically more accurate)
        for nutrient in fdc {
            mergedNutrients.append(nutrient)
            if let id = nutrient.id {
                processedNutrientIds.insert(id)
            }
        }

        // Add OFF nutrients that don't conflict with FDC
        for nutrient in off {
            if let id = nutrient.id, processedNutrientIds.contains(id) {
                continue // Skip if FDC already has this nutrient
            }

            // Check for name-based conflicts
            let hasConflict = fdc.contains { fdcNutrient in
                fdcNutrient.name.lowercased() == nutrient.name.lowercased() &&
                    fdcNutrient.unit.lowercased() == nutrient.unit.lowercased()
            }

            if !hasConflict {
                mergedNutrients.append(nutrient)
            }
        }

        return mergedNutrients
    }

    private func mergePortions(fdc: [NormalizedPortion], off: [NormalizedPortion]) -> [NormalizedPortion] {
        var mergedPortions: [NormalizedPortion] = []

        // Prefer FDC portions (they're typically more accurate)
        for portion in fdc {
            mergedPortions.append(portion)
        }

        // Add OFF portions that don't conflict
        for portion in off {
            let hasConflict = fdc.contains { fdcPortion in
                if fdcPortion.label.lowercased() == portion.label.lowercased() {
                    return true
                }
                if let fdcGrams = fdcPortion.grams, let portionGrams = portion.grams {
                    return abs(fdcGrams - portionGrams) < 1.0 // Within 1g tolerance
                }
                return false
            }

            if !hasConflict {
                mergedPortions.append(portion)
            }
        }

        return mergedPortions
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

    // MARK: - Helper Functions

    private func createEmptyNormalizedFood(_ gid: String, _ source: RawSource) -> NormalizedFood {
        let foodSource: FoodSource = source == .fdc ? .fdc : .off
        return NormalizedFood(
            gid: gid,
            source: foodSource,
            kind: .generic,
            barcode: nil,
            fetchedAt: "",
            primaryName: "Unknown Food",
            brand: nil,
            barcodes: [],
            imageUrl: nil,
            categoryIds: [],
            baseUnit: .grams,
            per100Base: [],
            densityGPerMl: nil,
            serving: nil,
            portions: [],
            nutrients: [],
            ingredientsText: nil,
            completeness: CompletenessFlags(),
            fieldSources: FieldSources(),
            userOverrides: UserOverrides()
        )
    }
}

// MARK: - Supporting Types

public struct NormalizedFood: Sendable, Codable, Equatable {
    public let gid: String
    public let source: FoodSource
    public let kind: FoodKind
    public let barcode: String?
    public let fetchedAt: String

    // Canonical fields
    public let primaryName: String
    public let brand: String?
    public let barcodes: [String]
    public let imageUrl: String?
    public let categoryIds: [String]

    // Base unit system
    public let baseUnit: BaseUnit // "g" or "ml"
    public let per100Base: [NormalizedNutrient] // nutrients normalized to 100 of baseUnit
    public let densityGPerMl: Double? // optional; only when we can compute from portions

    // Nutrition
    public let serving: NormalizedServing?
    public let portions: [NormalizedPortion]
    public let nutrients: [NormalizedNutrient] // legacy field for backward compatibility
    public let ingredientsText: String?

    // Metadata
    public let completeness: CompletenessFlags
    public let fieldSources: FieldSources
    public let userOverrides: UserOverrides

    // MARK: - Per-Serving Calculation

    /// Calculate per-serving nutrients for a given portion
    public func calculatePerServingNutrients(for portion: NormalizedPortion) -> [NormalizedNutrient] {
        guard let portionGrams = portion.grams, portionGrams > 0 else {
            return nutrients // Return original if no portion size
        }

        return nutrients.map { nutrient in
            guard nutrient.basis == .per100g else { return nutrient }

            return NormalizedNutrient(
                id: nutrient.id,
                name: nutrient.name,
                unit: nutrient.unit,
                amount: (nutrient.amount ?? 0) * (portionGrams / 100.0),
                basis: .perServing,
                source: nutrient.source
            )
        }
    }

    /// Get the default portion for this food (serving size or 100g)
    public var defaultPortion: NormalizedPortion? {
        // Prefer serving portion if available
        if let serving, let servingGrams = serving.grams {
            return NormalizedPortion(
                label: serving.household ?? "1 serving",
                grams: servingGrams,
                massG: servingGrams,
                volMl: nil, // Not available from serving info
                source: serving.source,
                estimateQuality: serving.estimateQuality
            )
        }

        // Fallback to 100g portion
        return portions.first { $0.grams == 100 }
    }
}

public struct NormalizedServing: Sendable, Codable, Equatable {
    public let amount: Double?
    public let unit: String?
    public let household: String?
    public let grams: Double?
    public let source: FoodSource
    public let estimateQuality: EstimateQuality
}

public struct NormalizedPortion: Sendable, Codable, Equatable {
    public let label: String
    public let grams: Double? // legacy field for backward compatibility
    public let massG: Double? // resolved mass in grams
    public let volMl: Double? // resolved volume in milliliters
    public let source: FoodSource
    public let estimateQuality: EstimateQuality
}

public struct NormalizedNutrient: Sendable, Codable, Equatable {
    public let id: Int?
    public let name: String
    public let unit: String
    public let amount: Double?
    public let basis: NutrientBasis
    public let source: FoodSource
}

public enum EstimateQuality: String, Sendable, Codable, CaseIterable {
    case exact
    case inferred
    case guessed
}

public struct CompletenessFlags: Sendable, Codable, Equatable {
    public let core: Bool
    public let label: Bool
    public let micros: Bool
    public let portions: Bool
    public let ingredients: Bool
    public let image: Bool

    public init(
        core: Bool = false,
        label: Bool = false,
        micros: Bool = false,
        portions: Bool = false,
        ingredients: Bool = false,
        image: Bool = false
    ) {
        self.core = core
        self.label = label
        self.micros = micros
        self.portions = portions
        self.ingredients = ingredients
        self.image = image
    }
}

public struct FieldSources: Sendable, Codable, Equatable {
    public let primaryName: FoodSource
    public let brand: FoodSource
    public let barcodes: FoodSource
    public let imageUrl: FoodSource
    public let nutrients: FoodSource
    public let serving: FoodSource
    public let portions: FoodSource
    public let ingredients: FoodSource

    public init(
        primaryName: FoodSource = .fdc,
        brand: FoodSource = .fdc,
        barcodes: FoodSource = .fdc,
        imageUrl: FoodSource = .fdc,
        nutrients: FoodSource = .fdc,
        serving: FoodSource = .fdc,
        portions: FoodSource = .fdc,
        ingredients: FoodSource = .fdc
    ) {
        self.primaryName = primaryName
        self.brand = brand
        self.barcodes = barcodes
        self.imageUrl = imageUrl
        self.nutrients = nutrients
        self.serving = serving
        self.portions = portions
        self.ingredients = ingredients
    }
}

public struct UserOverrides: Sendable, Codable, Equatable {
    // User overrides for food data
    public init() {}
}
