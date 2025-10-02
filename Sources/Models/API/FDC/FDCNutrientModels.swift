//
//  FDCNutrientModels.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - Nutrient Models

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

public struct ProxyLabelNutrient: Codable, Equatable {
    let value: Double?
}
