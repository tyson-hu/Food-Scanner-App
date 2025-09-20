//
//  FDCModels.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import Foundation

// Keep minimal so it doesn't collide with what already decode.
// Use later when we align the FDC client fully.

public struct FDCFoodSummary: Sendable, Codable, Equatable, Hashable {
    public let id: Int
    public let name: String
    public let brand: String?
    public let caloriesPerServing: Int
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

