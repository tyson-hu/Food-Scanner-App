//
//  FoodLoggingTypes.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - Unit Enum

/// Unit enum with household support for food portions
public enum Unit: Sendable, Codable, Equatable, Hashable {
    case grams
    case milliliters
    case serving
    case household(label: String)

    public var displayName: String {
        switch self {
        case .grams:
            return "g"
        case .milliliters:
            return "ml"
        case .serving:
            return "serving"
        case let .household(label):
            return label
        }
    }
}

// MARK: - Meal Enum

/// Meal type enum for categorizing food entries
public enum Meal: String, Sendable, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
}

// MARK: - Entry Kind Enum

/// Entry kind distinguishing between catalog and manual entries
public enum EntryKind: String, Sendable, Codable {
    case catalog
    case manual
}

// MARK: - Household Unit

/// Household unit metadata from API portions
public struct HouseholdUnit: Sendable, Codable, Equatable, Hashable {
    public let label: String // e.g., "1 can", "1 slice"
    public let grams: Double // resolved mass in grams

    public init(label: String, grams: Double) {
        self.label = label
        self.grams = grams
    }

    /// Normalized label for matching (lowercased, trimmed)
    public var normalizedLabel: String {
        label.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Static helper to normalize a label string
    public static func normalize(_ label: String) -> String {
        label.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Food Logging Nutrients

/// Food logging nutrients (sparse, nil = missing ≠ zero)
public struct FoodLoggingNutrients: Sendable, Equatable {
    public let energyKcal: Double?
    public let protein: Double?
    public let fat: Double?
    public let saturatedFat: Double?
    public let carbs: Double?
    public let fiber: Double?
    public let sugars: Double?
    public let addedSugars: Double?
    public let sodium: Double?
    public let cholesterol: Double?

    public init(
        energyKcal: Double? = nil,
        protein: Double? = nil,
        fat: Double? = nil,
        saturatedFat: Double? = nil,
        carbs: Double? = nil,
        fiber: Double? = nil,
        sugars: Double? = nil,
        addedSugars: Double? = nil,
        sodium: Double? = nil,
        cholesterol: Double? = nil
    ) {
        self.energyKcal = energyKcal
        self.protein = protein
        self.fat = fat
        self.saturatedFat = saturatedFat
        self.carbs = carbs
        self.fiber = fiber
        self.sugars = sugars
        self.addedSugars = addedSugars
        self.sodium = sodium
        self.cholesterol = cholesterol
    }

    /// Scale all nutrients by a factor (preserves nil values)
    public func scaled(by factor: Double) -> Self {
        .init(
            energyKcal: energyKcal.map { $0 * factor },
            protein: protein.map { $0 * factor },
            fat: fat.map { $0 * factor },
            saturatedFat: saturatedFat.map { $0 * factor },
            carbs: carbs.map { $0 * factor },
            fiber: fiber.map { $0 * factor },
            sugars: sugars.map { $0 * factor },
            addedSugars: addedSugars.map { $0 * factor },
            sodium: sodium.map { $0 * factor },
            cholesterol: cholesterol.map { $0 * factor }
        )
    }
}

// MARK: - FoodLoggingNutrients Codable Conformance

extension FoodLoggingNutrients: Codable {
    enum CodingKeys: String, CodingKey {
        case energyKcal
        case protein
        case fat
        case saturatedFat
        case carbs
        case fiber
        case sugars
        case addedSugars
        case sodium
        case cholesterol
    }

    public nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        energyKcal = try container.decodeIfPresent(Double.self, forKey: .energyKcal)
        protein = try container.decodeIfPresent(Double.self, forKey: .protein)
        fat = try container.decodeIfPresent(Double.self, forKey: .fat)
        saturatedFat = try container.decodeIfPresent(Double.self, forKey: .saturatedFat)
        carbs = try container.decodeIfPresent(Double.self, forKey: .carbs)
        fiber = try container.decodeIfPresent(Double.self, forKey: .fiber)
        sugars = try container.decodeIfPresent(Double.self, forKey: .sugars)
        addedSugars = try container.decodeIfPresent(Double.self, forKey: .addedSugars)
        sodium = try container.decodeIfPresent(Double.self, forKey: .sodium)
        cholesterol = try container.decodeIfPresent(Double.self, forKey: .cholesterol)
    }

    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(energyKcal, forKey: .energyKcal)
        try container.encodeIfPresent(protein, forKey: .protein)
        try container.encodeIfPresent(fat, forKey: .fat)
        try container.encodeIfPresent(saturatedFat, forKey: .saturatedFat)
        try container.encodeIfPresent(carbs, forKey: .carbs)
        try container.encodeIfPresent(fiber, forKey: .fiber)
        try container.encodeIfPresent(sugars, forKey: .sugars)
        try container.encodeIfPresent(addedSugars, forKey: .addedSugars)
        try container.encodeIfPresent(sodium, forKey: .sodium)
        try container.encodeIfPresent(cholesterol, forKey: .cholesterol)
    }
}
