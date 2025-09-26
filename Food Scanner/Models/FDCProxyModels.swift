//
//  FDCProxyModels.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//  Refactored from FDCModels.swift for better organization
//

import Foundation

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

struct Aggregations: Codable {
    let dataType: [String: Int]
    let nutrients: [String: AnyCodable]?
}
