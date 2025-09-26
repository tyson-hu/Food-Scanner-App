//
//  FDCNutrientModels.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//  Refactored from FDCModels.swift for better organization
//

import Foundation

// MARK: - Nutrient Models

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
