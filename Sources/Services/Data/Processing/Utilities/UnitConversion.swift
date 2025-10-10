//
//  UnitConversion.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - Data Normalization Utilities

enum DataNormalization {
    // MARK: - Energy Conversion

    /// Convert energy from kJ to kcal
    /// 1 kcal = 4.184 kJ
    nonisolated static func convertEnergyToKcal(_ value: Double, fromUnit unit: String) -> Double {
        let normalizedUnit = normalizeUnit(unit)

        switch normalizedUnit {
        case "kj", "kilojoule", "kilojoules":
            return value / 4.184
        case "kcal", "kilocalorie", "kilocalories", "cal", "calorie", "calories":
            return value
        default:
            // Assume kcal if unit is unknown
            return value
        }
    }

    /// Convert energy from kcal to kJ
    nonisolated static func convertEnergyToKj(_ value: Double, fromUnit unit: String) -> Double {
        let normalizedUnit = normalizeUnit(unit)

        switch normalizedUnit {
        case "kcal", "kilocalorie", "kilocalories", "cal", "calorie", "calories":
            return value * 4.184
        case "kj", "kilojoule", "kilojoules":
            return value
        default:
            // Assume kcal if unit is unknown
            return value * 4.184
        }
    }

    // MARK: - Unit Normalization

    /// Normalize unit strings for consistent comparison
    nonisolated static func normalizeUnit(_ unit: String?) -> String {
        guard let unit else { return "" }

        return unit
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
    }

    /// Normalize unit aliases (μg/mcg, etc.)
    nonisolated static func normalizeUnitAlias(_ unit: String?) -> String {
        guard let unit else { return "" }

        let normalized = normalizeUnit(unit)
        return normalizeUnitByCategory(normalized)
    }

    /// Normalize unit by category to reduce complexity
    private nonisolated static func normalizeUnitByCategory(_ unit: String) -> String {
        if let weightUnit = normalizeWeightUnit(unit) {
            return weightUnit
        }
        if let volumeUnit = normalizeVolumeUnit(unit) {
            return volumeUnit
        }
        if let cookingUnit = normalizeCookingUnit(unit) {
            return cookingUnit
        }
        return unit
    }

    /// Normalize weight units
    private nonisolated static func normalizeWeightUnit(_ unit: String) -> String? {
        switch unit {
        case "μg", "mcg", "microgram", "micrograms":
            "μg"
        case "mg", "milligram", "milligrams":
            "mg"
        case "g", "gram", "grams":
            "g"
        case "kg", "kilogram", "kilograms":
            "kg"
        case "oz", "ounce", "ounces":
            "oz"
        case "lb", "pound", "pounds":
            "lb"
        default:
            nil
        }
    }

    /// Normalize volume units
    private nonisolated static func normalizeVolumeUnit(_ unit: String) -> String? {
        switch unit {
        case "ml", "milliliter", "milliliters":
            "ml"
        case "l", "liter", "liters", "litre", "litres":
            "L"
        default:
            nil
        }
    }

    /// Normalize cooking units
    private nonisolated static func normalizeCookingUnit(_ unit: String) -> String? {
        switch unit {
        case "cup", "cups":
            "cup"
        case "tbsp", "tablespoon", "tablespoons":
            "tbsp"
        case "tsp", "teaspoon", "teaspoons":
            "tsp"
        default:
            nil
        }
    }

    // MARK: - String Hygiene

    /// Clean and normalize text strings
    nonisolated static func normalizeText(_ text: String?) -> String? {
        guard let text else { return nil }

        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        return cleaned.isEmpty ? nil : cleaned
    }

    /// Provide fallback text for missing values
    nonisolated static func fallbackText(_ text: String?, fallback: String = "—") -> String {
        guard let text, !text.isEmpty else { return fallback }
        return text
    }

    // MARK: - Serving Size Normalization

    /// Normalize serving size display
    nonisolated static func normalizeServingSize(size: Double?, unit: String?) -> String? {
        guard let size else { return nil }

        let normalizedUnit = normalizeUnitAlias(unit)
        let formattedSize = formatNumber(size)

        return "\(formattedSize) \(normalizedUnit)"
    }

    /// Format numbers for display (remove unnecessary decimals)
    nonisolated static func formatNumber(_ number: Double) -> String {
        if number.truncatingRemainder(dividingBy: 1) == 0 {
            String(format: "%.0f", number)
        } else {
            String(format: "%.1f", number)
        }
    }

    // MARK: - Nutrient Value Normalization

    /// Normalize nutrient values with proper units
    nonisolated static func normalizeNutrientValue(_ value: Double?, unit: String?) -> (value: Double, unit: String)? {
        guard let value else { return nil }

        let normalizedUnit = normalizeUnitAlias(unit)
        let formattedValue = formatNumber(value)

        return (Double(formattedValue) ?? value, normalizedUnit)
    }

    // MARK: - Brand Name Normalization

    /// Normalize brand names for consistent display
    nonisolated static func normalizeBrandName(_ brand: String?) -> String? {
        guard let brand else { return nil }

        let cleaned = normalizeText(brand)
        return cleaned?.isEmpty == false ? cleaned : nil
    }

    /// Combine brand owner and brand name intelligently
    nonisolated static func combineBrandNames(owner: String?, name: String?) -> String? {
        let normalizedOwner = normalizeBrandName(owner)
        let normalizedName = normalizeBrandName(name)

        switch (normalizedOwner, normalizedName) {
        case let (owner?, name?) where owner != name:
            return "\(name) (\(owner))"
        case (let owner?, nil):
            return owner
        case (nil, let name?):
            return name
        case let (owner?, name?) where owner == name:
            return name
        default:
            return nil
        }
    }

    // MARK: - Date Normalization

    /// Normalize date strings from FDC API
    nonisolated static func normalizeDate(_ dateString: String?) -> String? {
        guard let dateString else { return nil }

        // FDC dates are typically in ISO format, but let's clean them up
        let cleaned = normalizeText(dateString)

        // Try to parse and reformat the date
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: cleaned ?? "") {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }

        return cleaned
    }

    // MARK: - UPC/Barcode Normalization

    /// Normalize UPC/GTIN codes
    nonisolated static func normalizeUPC(_ upc: String?) -> String? {
        guard let upc else { return nil }

        let cleaned = upc.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    // MARK: - Food Category Normalization

    /// Normalize food category names
    nonisolated static func normalizeFoodCategory(_ category: String?) -> String? {
        guard let category else { return nil }

        let cleaned = normalizeText(category)
        return cleaned?.isEmpty == false ? cleaned : nil
    }

    // MARK: - Ingredients Normalization

    /// Normalize ingredients list
    nonisolated static func normalizeIngredients(_ ingredients: String?) -> String? {
        guard let ingredients else { return nil }

        let cleaned = normalizeText(ingredients)
        return cleaned?.isEmpty == false ? cleaned : nil
    }
}
