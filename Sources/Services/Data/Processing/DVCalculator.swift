//
//  DVCalculator.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

/// Daily Value constants for %DV calculations
public struct DVConstants: Sendable {
    public static let energy: Double = 2_000 // kcal
    public static let protein: Double = 50 // g
    public static let fat: Double = 78 // g
    public static let saturatedFat: Double = 20 // g
    public static let carbs: Double = 275 // g
    public static let fiber: Double = 28 // g
    public static let sodium: Double = 2_300 // mg
    public static let cholesterol: Double = 300 // mg
}

/// Service for calculating Daily Value percentages
public struct DVCalculator: Sendable {
    /// Calculate percentage of Daily Value for a given nutrient and amount
    /// Returns nil for nutrients that don't have established DV values
    public static func percentDV(for nutrient: String, amount: Double) -> Double? {
        guard amount >= 0 else { return nil }

        let normalizedNutrient = normalizeNutrientName(nutrient)
        guard let dvConstant = getDVConstant(for: normalizedNutrient) else { return nil }

        return (amount / dvConstant) * 100
    }

    /// Calculate %DV for multiple nutrients at once
    public static func percentDVs(for nutrients: [String: Double]) -> [String: Double] {
        var result: [String: Double] = [:]

        for (nutrient, amount) in nutrients {
            if let percentDV = percentDV(for: nutrient, amount: amount) {
                result[nutrient] = percentDV
            }
        }

        return result
    }

    // MARK: - Private Helpers

    private static func normalizeNutrientName(_ nutrient: String) -> String {
        nutrient.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private static func getDVConstant(for nutrient: String) -> Double? {
        switch nutrient {
        case "energy", "calories", "kcal":
            return DVConstants.energy
        case "protein":
            return DVConstants.protein
        case "fat", "total fat":
            return DVConstants.fat
        case "saturated fat", "saturatedfat":
            return DVConstants.saturatedFat
        case "carbs", "carbohydrate", "carbohydrates", "total carbohydrate":
            return DVConstants.carbs
        case "fiber", "dietary fiber":
            return DVConstants.fiber
        case "sodium":
            return DVConstants.sodium
        case "cholesterol":
            return DVConstants.cholesterol
        // Nutrients without established DV values
        case "sugars", "total sugars", "added sugars", "addedsugars":
            return nil
        default:
            return nil
        }
    }
}
