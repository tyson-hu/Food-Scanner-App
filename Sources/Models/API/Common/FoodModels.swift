//
//  FoodModels.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - New API Models (v1 Worker API)

// MARK: - Minimal Card (for /food/* and /barcode/* endpoints)

public struct FoodMinimalCard: Sendable, Codable, Equatable, Hashable {
    public let id: String // GID: "gtin:<14>" | "fdc:<id>" | "dsld:<id>"
    public let kind: FoodKind
    public let code: String? // raw barcode when known (no padding)
    public let description: String?
    public let brand: String?
    public let baseUnit: BaseUnit // "g" or "ml"
    public let per100Base: [FoodNutrient] // nutrients normalized to 100 of baseUnit
    public let serving: FoodServing?
    public let portions: [FoodPortion]?
    public let densityGPerMl: Double? // optional; only when we can compute from portions
    public let nutrients: [FoodNutrient] // legacy field for backward compatibility
    public let provenance: FoodProvenance
}

// MARK: - Authoritative Detail (for /foodDetails/* endpoint)

public struct FoodAuthoritativeDetail: Sendable, Codable, Equatable {
    public let id: String // GID
    public let kind: FoodKind
    public let code: String?
    public let description: String?
    public let brand: String?
    public let ingredientsText: String?
    public let baseUnit: BaseUnit // "g" or "ml"
    public let per100Base: [FoodNutrient] // nutrients normalized to 100 of baseUnit
    public let serving: FoodServing?
    public let portions: [FoodPortion]
    public let densityGPerMl: Double? // optional; only when we can compute from portions
    public let nutrients: [FoodNutrient] // legacy field for backward compatibility
    public let dsidPredictions: [DSIDPrediction]?
    public let provenance: FoodProvenance
}

// MARK: - Search Response (for /search endpoint)

public struct FoodSearchResponse: Sendable, Codable, Equatable {
    public let query: String
    public let generic: [FoodMinimalCard]
    public let branded: [FoodMinimalCard]
}

// MARK: - Health Response (for /health endpoint)

public struct FoodHealthResponse: Sendable, Codable, Equatable {
    public let isHealthy: Bool
    public let sources: [String: String]
}

// MARK: - Supporting Types

public enum FoodKind: String, Sendable, Codable, CaseIterable {
    case supplement
    case branded = "branded_food"
    case generic = "generic_food"
}

public enum BaseUnit: String, Sendable, Codable, CaseIterable {
    case grams = "g"
    case milliliters = "ml"

    public var displayName: String {
        switch self {
        case .grams:
            return "g"
        case .milliliters:
            return "ml"
        }
    }

    public var per100DisplayName: String {
        switch self {
        case .grams:
            return "per 100 g"
        case .milliliters:
            return "per 100 ml"
        }
    }
}

public struct FoodServing: Sendable, Codable, Equatable, Hashable {
    public let amount: Double?
    public let unit: String?
    public let household: String?
}

public struct FoodPortion: Sendable, Codable, Equatable, Hashable {
    public let label: String // e.g., "can", "cup", "piece"
    public let amount: Double?
    public let unit: String?
    public let household: String?
    public let massG: Double? // resolved mass in grams
    public let volMl: Double? // resolved volume in milliliters
}

public struct FoodNutrient: Sendable, Codable, Equatable, Hashable {
    public let id: Int? // FDC nutrient id when available
    public let name: String
    public let unit: String
    public let amount: Double?
    public let basis: NutrientBasis
}

public enum NutrientBasis: String, Sendable, Codable, CaseIterable {
    case perServing = "per_serving"
    case per100g = "per_100g"
    case per100Base = "per_100_base" // per 100 of the food's base unit (g or ml)
}

public struct FoodProvenance: Sendable, Codable, Equatable, Hashable {
    public let source: SourceTag
    public let id: String
    public let fetchedAt: String // ISO 8601 timestamp
}

public enum SourceTag: String, Sendable, Codable, CaseIterable {
    case fdc
    case dsld
    case dsid
    case off
}

public struct DSIDPrediction: Sendable, Codable, Equatable, Hashable {
    public let studyCode: String
    public let ingredient: String
    public let labelAmount: Double
    public let unit: String
    public let pctDiffFromLabel: Double
    public let predMeanValue: Double
    public let ci95PredMeanLow: Double
    public let ci95PredMeanHigh: Double

    enum CodingKeys: String, CodingKey {
        case studyCode = "study_code"
        case ingredient
        case labelAmount = "label_amount"
        case unit
        case pctDiffFromLabel = "pct_diff_from_label"
        case predMeanValue = "pred_mean_value"
        case ci95PredMeanLow = "ci95_pred_mean_low"
        case ci95PredMeanHigh = "ci95_pred_mean_high"
    }
}

// MARK: - Legacy Models (for backward compatibility)

public struct FDCFoodSummary: Sendable, Codable, Equatable, Hashable {
    public let id: Int
    public let name: String
    public let brand: String?
    public let serving: String?
    public let upc: String?
    public let publishedDate: String?
    public let modifiedDate: String?

    // Enhanced fields for comprehensive schema coverage
    public let dataType: String?
    public let brandOwner: String?
    public let brandName: String?
    public let servingSize: Double?
    public let servingSizeUnit: String?
    public let householdServingFullText: String?
    public let packageWeight: String?
    public let foodCategory: String?
    public let foodCategoryId: Int?
    public let ingredients: String?
    public let marketCountry: String?
    public let tradeChannels: [String]?

    // Label nutrients for quick glance
    public let calories: Double?
    public let protein: Double?
    public let fat: Double?
    public let saturatedFat: Double?
    public let transFat: Double?
    public let cholesterol: Double?
    public let sodium: Double?
    public let carbohydrates: Double?
    public let fiber: Double?
    public let sugars: Double?
    public let calcium: Double?
    public let iron: Double?
    public let potassium: Double?

    // Food nutrients summary
    public let macroSummary: MacroSummary?
}

public struct MacroSummary: Sendable, Codable, Equatable, Hashable {
    public let calories: Double
    public let protein: Double
    public let fat: Double
    public let carbohydrates: Double
    public let fiber: Double?
    public let sugars: Double?
}

public struct FDCFoodDetails: Sendable, Codable, Equatable {
    public let id: Int
    public let name: String
    public let brand: String?
    public let calories: Int
    public let protein: Int
    public let fat: Int
    public let carbs: Int

    // Enhanced fields for comprehensive details
    public let dataType: String?
    public let brandOwner: String?
    public let brandName: String?
    public let servingSize: Double?
    public let servingSizeUnit: String?
    public let householdServingFullText: String?
    public let packageWeight: String?
    public let foodCategory: String?
    public let foodCategoryId: Int?
    public let ingredients: String?
    public let marketCountry: String?
    public let tradeChannels: [String]?
    public let publishedDate: String?
    public let modifiedDate: String?
    public let gtinUpc: String?

    // Complete label nutrients
    public let labelNutrients: LabelNutrients?

    // Complete food nutrients
    public let foodNutrients: [FoodNutrient]?
}

public struct LabelNutrients: Sendable, Codable, Equatable {
    public let calories: NutrientValue?
    public let fat: NutrientValue?
    public let saturatedFat: NutrientValue?
    public let transFat: NutrientValue?
    public let cholesterol: NutrientValue?
    public let sodium: NutrientValue?
    public let carbohydrates: NutrientValue?
    public let fiber: NutrientValue?
    public let sugars: NutrientValue?
    public let protein: NutrientValue?
    public let calcium: NutrientValue?
    public let iron: NutrientValue?
    public let potassium: NutrientValue?
}

public struct NutrientValue: Sendable, Codable, Equatable {
    public let value: Double
    public let unit: String?
}
