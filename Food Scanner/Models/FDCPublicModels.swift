//
//  FDCPublicModels.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//  Refactored from FDCModels.swift for better organization
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
