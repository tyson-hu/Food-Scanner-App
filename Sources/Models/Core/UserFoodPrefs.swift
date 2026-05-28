//
//  UserFoodPrefs.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import SwiftData

@Model
public final class UserFoodPrefs {
    public var userId: String // For future multi-user (use "default" for now)
    public var foodGID: String // Link to FoodRef
    public var defaultUnitRaw: String // Unit enum encoded
    public var defaultQty: Double
    public var defaultMealRaw: String // Meal enum encoded
    public var updatedAt: Date

    public init(
        foodGID: String,
        defaultUnit: Unit,
        defaultQty: Double,
        defaultMeal: Meal,
        userId: String = "default"
    ) {
        self.userId = userId
        self.foodGID = foodGID
        defaultUnitRaw = Self.encodeUnit(defaultUnit)
        self.defaultQty = defaultQty
        defaultMealRaw = defaultMeal.rawValue
        updatedAt = .now
    }

    // Computed properties
    public var defaultUnit: Unit {
        get { Self.decodeUnit(defaultUnitRaw) }
        set {
            defaultUnitRaw = Self.encodeUnit(newValue)
            updatedAt = .now
        }
    }

    public var defaultMeal: Meal {
        get { Meal(rawValue: defaultMealRaw) ?? Meal.lunch }
        set {
            defaultMealRaw = newValue.rawValue
            updatedAt = .now
        }
    }

    // Helper methods for Unit encoding (since it has associated values)
    private static func encodeUnit(_ unit: Unit) -> String {
        switch unit {
        case .grams:
            return "grams"
        case .milliliters:
            return "milliliters"
        case .serving:
            return "serving"
        case let .household(label):
            return "household:\(label)"
        }
    }

    private static func decodeUnit(_ raw: String) -> Unit {
        if raw == "grams" { return .grams }
        if raw == "milliliters" { return .milliliters }
        if raw == "serving" { return .serving }
        if raw.hasPrefix("household:") {
            let label = String(raw.dropFirst("household:".count))
            return .household(label: label)
        }
        return .serving // fallback
    }
}
