//
//  FDCLegacyModels.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - Legacy Models (for backward compatibility)

struct FDCResponse: Codable {
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
