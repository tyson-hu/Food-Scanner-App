//
//  SnapshotNutrientCalculator.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

/// Service for calculating nutrient snapshots from per100 nutrients using portion resolution
public struct SnapshotNutrientCalculator: Sendable {
    /// Parameters for nutrient snapshot calculation
    public struct CalculationParams: Sendable {
        public let quantity: Double
        public let unit: Unit
        public let gramsPerServing: Double?
        public let densityGPerMl: Double?
        public let householdUnits: [HouseholdUnit]?

        public init(
            quantity: Double,
            unit: Unit,
            gramsPerServing: Double? = nil,
            densityGPerMl: Double? = nil,
            householdUnits: [HouseholdUnit]? = nil
        ) {
            self.quantity = quantity
            self.unit = unit
            self.gramsPerServing = gramsPerServing
            self.densityGPerMl = densityGPerMl
            self.householdUnits = householdUnits
        }
    }

    /// Calculate nutrient snapshot from per100 nutrients using portion resolution
    public static func calculateSnapshot(
        per100Nutrients: FoodLoggingNutrients,
        params: CalculationParams
    ) -> FoodLoggingNutrients {
        guard let grams = PortionResolver.resolveToGrams(
            quantity: params.quantity,
            unit: params.unit,
            gramsPerServing: params.gramsPerServing,
            densityGPerMl: params.densityGPerMl,
            householdUnits: params.householdUnits
        ) else { return .init() }
        return per100Nutrients.scaled(by: grams / 100.0)
    }
}
