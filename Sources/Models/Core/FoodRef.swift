//
//  FoodRef.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import SwiftData

@Model
public final class FoodRef {
    @Attribute(.unique) public var gid: String // "fdc:123" or "off:0123456789012"
    public var source: SourceTag // .fdc or .off (reuse existing)
    public var name: String
    public var brand: String?

    // Serving metadata
    public var servingSize: Double? // from FoodServing.amount
    public var servingSizeUnit: String? // from FoodServing.unit
    public var gramsPerServing: Double? // calculated or from portions

    // Household units (encoded as Data)
    public var householdUnitsData: Data? // [HouseholdUnit] encoded

    // Label nutrients (sparse, encoded as Data)
    public var foodLoggingNutrientsData: Data? // FoodLoggingNutrients encoded

    // Metadata
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        gid: String,
        source: SourceTag,
        name: String,
        brand: String? = nil,
        servingSize: Double? = nil,
        servingSizeUnit: String? = nil,
        gramsPerServing: Double? = nil,
        householdUnits: [HouseholdUnit]? = nil,
        foodLoggingNutrients: FoodLoggingNutrients? = nil
    ) {
        self.gid = gid
        self.source = source
        self.name = name
        self.brand = brand
        self.servingSize = servingSize
        self.servingSizeUnit = servingSizeUnit
        self.gramsPerServing = gramsPerServing
        createdAt = .now
        updatedAt = .now

        // Encode complex types to Data
        if let units = householdUnits {
            householdUnitsData = try? JSONEncoder().encode(units)
        }
        if let nutrients = foodLoggingNutrients {
            foodLoggingNutrientsData = try? JSONEncoder().encode(nutrients)
        }
    }

    // Computed properties for easy access
    public nonisolated var householdUnits: [HouseholdUnit]? {
        get {
            guard let data = householdUnitsData else { return nil }
            return try? JSONDecoder().decode([HouseholdUnit].self, from: data)
        }
        set {
            householdUnitsData = newValue.flatMap { try? JSONEncoder().encode($0) }
            updatedAt = .now
        }
    }

    public nonisolated var foodLoggingNutrients: FoodLoggingNutrients? {
        get {
            guard let data = foodLoggingNutrientsData else { return nil }
            return try? JSONDecoder().decode(FoodLoggingNutrients.self, from: data)
        }
        set {
            foodLoggingNutrientsData = newValue.flatMap { try? JSONEncoder().encode($0) }
            updatedAt = .now
        }
    }
}
