//
//  FDCFoodDetailModels.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//  Refactored from FDCModels.swift for better organization
//

import Foundation

// MARK: - Detailed Food Response Models

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
