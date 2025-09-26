//
//  FDCModels.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import Foundation

// MARK: - Public API Models (unchanged interface)

public struct FDCFoodSummary: Sendable, Codable, Equatable, Hashable {
    public let id: Int
    public let name: String
    public let brand: String?
    public let serving: String?
    public let upc: String?
    public let publishedDate: String?
    public let modifiedDate: String?
}

public struct FDCFoodDetails: Sendable, Codable, Equatable {
    public let id: Int
    public let name: String
    public let brand: String?
    public let calories: Int
    public let protein: Int
    public let fat: Int
    public let carbs: Int
}

// MARK: - Proxy API Response Models (matches observed envelope)

struct ProxySearchResponse: Codable {
    let totalHits: Int
    let currentPage: Int
    let totalPages: Int
    let pageList: [Int]
    let foodSearchCriteria: FoodSearchCriteria
    let foods: [ProxyFoodItem]
    let aggregations: Aggregations?
}

struct FoodSearchCriteria: Codable {
    let dataType: [String]
    let query: String
    let generalSearchInput: String
    let pageNumber: Int
    let numberOfResultsPerPage: Int
    let pageSize: Int
    let requireAllWords: Bool
    let foodTypes: [String]
}

struct ProxyFoodItem: Codable {
    let fdcId: Int
    let description: String
    let dataType: String
    let gtinUpc: String?
    let publishedDate: String?
    let brandOwner: String?
    let brandName: String?
    let ingredients: String?
    let marketCountry: String?
    let foodCategory: String?
    let modifiedDate: String?
    let dataSource: String?
    let packageWeight: String?
    let servingSizeUnit: String?
    let servingSize: Double?
    let householdServingFullText: String?
    let tradeChannels: [String]?
    let allHighlightFields: String?
    let score: Double?
    let microbes: [String]?
    let foodNutrients: [ProxyFoodNutrient]?
    let finalFoodInputFoods: [String]?
    let foodMeasures: [String]?
    let foodAttributes: [AnyCodable]?
    let foodAttributeTypes: [AnyCodable]?
    let foodVersionIds: [String]?
}

// New model for single food detail response from Calry API
public struct ProxyFoodDetailResponse: Codable, Equatable {
    let fdcId: Int
    let description: String
    let publicationDate: String?
    let foodNutrients: [ProxyFoodNutrient]?
    let dataType: String?
    let foodClass: String?
    let inputFoods: [ProxyInputFood]?
    let foodComponents: [AnyCodable]?
    let foodAttributes: [AnyCodable]?
    let nutrientConversionFactors: [ProxyNutrientConversionFactor]?
    let ndbNumber: Int?
    let isHistoricalReference: Bool?
    let foodCategory: ProxyFoodCategory?

    // Additional fields from Calry API
    let brandOwner: String?
    let brandName: String?
    let dataSource: String?
    let gtinUpc: String?
    let marketCountry: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let householdServingFullText: String?
    let ingredients: String?
    let brandedFoodCategory: String?
    let packageWeight: String?
    let discontinuedDate: String?
    let availableDate: String?
    let modifiedDate: String?
    let foodPortions: [ProxyFoodPortion]?
    let foodUpdateLog: [AnyCodable]?
    let labelNutrients: ProxyLabelNutrients?

    // Additional fields from FDC API schema
    let scientificName: String?
    let footNote: String?
    let foodCode: String?
    let endDate: String?
    let startDate: String?
    let wweiaFoodCategory: ProxyWweiaFoodCategory?
    let foodMeasures: [ProxyFoodMeasure]?
    let microbes: [String]?
    let tradeChannels: [String]?
    let allHighlightFields: String?
    let score: Double?
    let foodVersionIds: [String]?
    let foodAttributeTypes: [AnyCodable]?
    let finalFoodInputFoods: [String]?
}

public struct ProxyInputFood: Codable, Equatable {
    let id: Int?
    let foodDescription: String?
    let inputFood: ProxyInputFoodDetail?
}

public struct ProxyInputFoodDetail: Codable, Equatable {
    let fdcId: Int?
    let description: String?
    let publicationDate: String?
    let foodAttributeTypes: [AnyCodable]?
    let foodClass: String?
    let totalRefuse: Int?
    let dataType: String?
    let foodGroup: ProxyFoodGroup?
}

public struct ProxyFoodGroup: Codable, Equatable {
    let id: Int?
    let code: String?
    let description: String?
}

public struct ProxyFoodCategory: Codable, Equatable {
    let id: Int?
    let code: String?
    let description: String?
}

public struct ProxyWweiaFoodCategory: Codable, Equatable {
    let wweiaFoodCategoryCode: Int?
    let wweiaFoodCategoryDescription: String?
}

public struct ProxyFoodPortion: Codable, Equatable {
    let id: Int?
    let amount: Double?
    let dataPoints: Int?
    let gramWeight: Double?
    let minYearAcquired: Int?
    let modifier: String?
    let portionDescription: String?
    let sequenceNumber: Int?
    let measureUnit: ProxyMeasureUnit?
}

public struct ProxyMeasureUnit: Codable, Equatable {
    let id: Int?
    let abbreviation: String?
    let name: String?
}

public struct ProxyFoodMeasure: Codable, Equatable {
    let id: Int?
    let amount: Double?
    let gramWeight: Double?
    let modifier: String?
    let portionDescription: String?
    let sequenceNumber: Int?
    let measureUnit: ProxyMeasureUnit?
}

public struct ProxyNutrientConversionFactor: Codable, Equatable {
    let id: Int?
    let proteinValue: Double?
    let fatValue: Double?
    let carbohydrateValue: Double?
    let type: String?
    let name: String?
    let value: Double?
}

public struct ProxyFoodNutrient: Codable, Equatable {
    let nutrient: ProxyNutrient?
    let amount: Double?
    let type: String?
    let foodNutrientDerivation: ProxyFoodNutrientDerivation?
    let id: Int?
    let dataPoints: Int?
    let max: Double?
    let min: Double?
    let median: Double?
    let minYearAcquired: Int?
    let nutrientAnalysisDetails: [ProxyNutrientAnalysisDetail]?
}

public struct ProxyNutrient: Codable, Equatable {
    let id: Int?
    let number: String?
    let name: String?
    let rank: Int?
    let unitName: String?
}

public struct ProxyFoodNutrientDerivation: Codable, Equatable {
    let id: Int?
    let code: String?
    let description: String?
    let foodNutrientSource: ProxyFoodNutrientSource?
}

public struct ProxyFoodNutrientSource: Codable, Equatable {
    let id: Int?
    let code: String?
    let description: String?
}

public struct ProxyNutrientAnalysisDetail: Codable, Equatable {
    let subSampleId: Int?
    let nutrientId: Int?
    let nutrientAcquisitionDetails: [ProxyNutrientAcquisitionDetail]?
    let amount: Double?
    let labMethodTechnique: String?
    let labMethodDescription: String?
    let labMethodOriginalDescription: String?
    let labMethodLink: String?
}

public struct ProxyNutrientAcquisitionDetail: Codable, Equatable {
    let sampleUnitId: Int?
    let purchaseDate: String?
    let storeCity: String?
    let storeState: String?
    let packerCity: String?
    let packerState: String?
}

public struct ProxyLabelNutrients: Codable, Equatable {
    let fat: ProxyLabelNutrient?
    let saturatedFat: ProxyLabelNutrient?
    let transFat: ProxyLabelNutrient?
    let cholesterol: ProxyLabelNutrient?
    let sodium: ProxyLabelNutrient?
    let carbohydrates: ProxyLabelNutrient?
    let fiber: ProxyLabelNutrient?
    let sugars: ProxyLabelNutrient?
    let protein: ProxyLabelNutrient?
    let calcium: ProxyLabelNutrient?
    let iron: ProxyLabelNutrient?
    let calories: ProxyLabelNutrient?
}

public struct ProxyLabelNutrient: Codable, Equatable {
    let value: Double?
}

struct Aggregations: Codable {
    let dataType: [String: Int]
    let nutrients: [String: AnyCodable]?
}

public struct AnyCodable: Codable, Equatable {
    let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as different types in order of likelihood
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue
        } else {
            // If all else fails, try to decode as a generic dictionary
            // This handles cases where the structure might be more complex
            let genericDict = try container.decode([String: AnyCodable].self)
            value = genericDict
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let arrayValue = value as? [AnyCodable] {
            try container.encode(arrayValue)
        } else if let dictValue = value as? [String: AnyCodable] {
            try container.encode(dictValue)
        } else {
            // If all else fails, encode as empty dictionary
            try container.encode([String: AnyCodable]())
        }
    }

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Simple comparison based on type and value
        switch (lhs.value, rhs.value) {
        case let (lhsInt as Int, rhsInt as Int):
            lhsInt == rhsInt
        case let (lhsString as String, rhsString as String):
            lhsString == rhsString
        case let (lhsDouble as Double, rhsDouble as Double):
            lhsDouble == rhsDouble
        case let (lhsBool as Bool, rhsBool as Bool):
            lhsBool == rhsBool
        case let (lhsArray as [AnyCodable], rhsArray as [AnyCodable]):
            lhsArray == rhsArray
        case let (lhsDict as [String: AnyCodable], rhsDict as [String: AnyCodable]):
            lhsDict == rhsDict
        default:
            false
        }
    }
}

// MARK: - Legacy Models (for backward compatibility)

struct FDCAPIResponse: Codable {
    let foods: [FDCFoodItem]
    let totalHits: Int
    let currentPage: Int
    let totalPages: Int
}

struct FDCFoodItem: Codable {
    let fdcId: Int
    let description: String
    let brandOwner: String?
    let foodNutrients: [FDCFoodNutrient]

    enum CodingKeys: String, CodingKey {
        case fdcId
        case description
        case brandOwner
        case foodNutrients
    }
}

struct FDCFoodNutrient: Codable {
    let nutrient: FDCNutrient
    let amount: Double
}

struct FDCNutrient: Codable {
    let id: Int
    let name: String
    let unitName: String
}

// MARK: - Conversion Extensions

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
        // Extract nutrients by searching through available nutrients
        var calories: Double = 0
        var protein: Double = 0
        var fat: Double = 0
        var carbs: Double = 0

        // Search through all nutrients to find the ones we need
        if let nutrients = foodNutrients {
            for nutrient in nutrients {
                guard let nutrientId = nutrient.nutrient?.id,
                      let amount = nutrient.amount else { continue }

                switch nutrientId {
                case 2047, 2048: // Energy (Atwater General Factors or Specific Factors)
                    calories = amount
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
        }

        let brand = brandOwner ?? brandName ?? ""

        return FDCFoodDetails(
            id: fdcId,
            name: description.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.isEmpty ? nil : brand,
            calories: Int(calories),
            protein: Int(protein),
            fat: Int(fat),
            carbs: Int(carbs)
        )
    }
}

// Conversion extension for ProxyFoodDetailResponse
extension ProxyFoodDetailResponse {
    func toFDCFoodDetails() -> FDCFoodDetails {
        // Extract nutrients by searching through available nutrients
        var calories: Double = 0
        var protein: Double = 0
        var fat: Double = 0
        var carbs: Double = 0

        // Search through all nutrients to find the ones we need
        if let nutrients = foodNutrients {
            for nutrient in nutrients {
                guard let nutrientId = nutrient.nutrient?.id,
                      let amount = nutrient.amount else { continue }

                switch nutrientId {
                case 2047, 2048: // Energy (Atwater General Factors or Specific Factors)
                    calories = amount
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
        }

        let brand = brandOwner ?? brandName ?? ""

        return FDCFoodDetails(
            id: fdcId,
            name: description.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.isEmpty ? nil : brand,
            calories: Int(calories),
            protein: Int(protein),
            fat: Int(fat),
            carbs: Int(carbs)
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
